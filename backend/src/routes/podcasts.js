const express = require('express');
const { query, param } = require('express-validator');
const db = require('../config/database');
const { asyncHandler } = require('../middleware/errorHandler');
const { optionalAuth } = require('../middleware/auth');
const logger = require('../utils/logger');

const router = express.Router();

// Test database connection
router.get('/test', asyncHandler(async (req, res) => {
  try {
    console.log('🔍 Testing podcast database connection...');
    const result = await db.raw('SELECT 1 as test');
    console.log('✅ Podcast database test result:', result);
    res.json({
      success: true,
      message: 'Podcast database connection working',
      result: result[0]
    });
  } catch (error) {
    console.error('❌ Podcast database test failed:', error);
    res.status(500).json({
      success: false,
      error: 'Podcast database connection failed',
      details: error.message
    });
  }
}));

// Get all podcasts with pagination and filters
router.get('/', asyncHandler(async (req, res) => {
  try {
    console.log('🔍 Podcasts endpoint called with query:', req.query);
    const { page = 1, limit = 20, search, category, language, featured, sortBy = 'created_at', sortOrder = 'desc' } = req.query;
    const offset = (page - 1) * limit;
    console.log('📊 Podcasts endpoint params:', { page, limit, offset, search, category, language, featured, sortBy, sortOrder });

    let query = db('podcasts')
      .select(
        'id', 'title', 'title_somali', 'description', 'description_somali',
        'host', 'host_somali', 'language', 'cover_image_url', 'rss_feed_url',
        'website_url', 'total_episodes', 'rating', 'review_count',
        'is_featured', 'is_new_release', 'is_premium', 'is_free',
        'metadata', 'created_at', 'updated_at'
      );

    // Apply search filter
    if (search) {
      query = query.where(function() {
        this.where('title', 'like', `%${search}%`)
          .orWhere('title_somali', 'like', `%${search}%`)
          .orWhere('description', 'like', `%${search}%`)
          .orWhere('description_somali', 'like', `%${search}%`)
          .orWhere('host', 'like', `%${search}%`)
          .orWhere('host_somali', 'like', `%${search}%`);
      });
    }

    // Apply category filter
    if (category && category !== 'all') {
      query = query.whereExists(function() {
        this.select('*')
          .from('podcast_categories')
          .whereRaw('podcast_categories.podcast_id = podcasts.id')
          .where('podcast_categories.category_id', category);
      });
    }

    // Apply language filter
    if (language && language !== 'all') {
      query = query.where('language', language);
    }

    // Apply featured filter
    if (featured && featured !== 'all') {
      query = query.where('is_featured', featured === 'true');
    }

    // Get total count
    let countQuery = db('podcasts');
    
    // Apply the same filters to the count query
    if (search) {
      countQuery = countQuery.where(function() {
        this.where('title', 'like', `%${search}%`)
          .orWhere('title_somali', 'like', `%${search}%`)
          .orWhere('description', 'like', `%${search}%`)
          .orWhere('description_somali', 'like', `%${search}%`)
          .orWhere('host', 'like', `%${search}%`)
          .orWhere('host_somali', 'like', `%${search}%`);
      });
    }
    if (category && category !== 'all') {
      countQuery = countQuery.whereExists(function() {
        this.select('*')
          .from('podcast_categories')
          .whereRaw('podcast_categories.podcast_id = podcasts.id')
          .where('podcast_categories.category_id', category);
      });
    }
    if (language && language !== 'all') {
      countQuery = countQuery.where('language', language);
    }
    if (featured && featured !== 'all') {
      countQuery = countQuery.where('is_featured', featured === 'true');
    }

    const totalCount = await countQuery.count('* as count').first();
    const totalPages = Math.ceil(totalCount.count / limit);

    // Get podcasts
    const podcasts = await query
      .orderBy(sortBy, sortOrder)
      .limit(limit)
      .offset(offset);

    console.log('🎙️ Retrieved podcasts:', podcasts.length);

    // Process podcasts to handle JSON fields and fetch categories
    const processedPodcasts = await Promise.all(podcasts.map(async (podcast) => {
      // Fetch categories for this podcast
      const categories = await db('podcast_categories')
        .join('categories', 'podcast_categories.category_id', 'categories.id')
        .where('podcast_categories.podcast_id', podcast.id)
        .where('categories.is_active', true)
        .select('categories.id', 'categories.name', 'categories.name_somali')
        .orderBy('categories.sort_order', 'asc');

      return {
        id: podcast.id,
        title: podcast.title,
        titleSomali: podcast.title_somali,
        description: podcast.description,
        descriptionSomali: podcast.description_somali,
        host: podcast.host || '',
        hostSomali: podcast.host_somali || '',
        language: podcast.language,
        coverImageUrl: podcast.cover_image_url,
        rssFeedUrl: podcast.rss_feed_url,
        websiteUrl: podcast.website_url,
        totalEpisodes: podcast.total_episodes,
        rating: podcast.rating,
        reviewCount: podcast.review_count,
        isFeatured: Boolean(podcast.is_featured),
        isNewRelease: Boolean(podcast.is_new_release),
        isPremium: Boolean(podcast.is_premium),
        isFree: Boolean(podcast.is_free),
        metadata: podcast.metadata,
        createdAt: podcast.created_at,
        updatedAt: podcast.updated_at,
        categories: categories.map(cat => cat.id),
        categoryNames: categories.map(cat => cat.name),
        categoryNamesSomali: categories.map(cat => cat.name_somali),
      };
    }));

    res.json({
      success: true,
      podcasts: processedPodcasts,
      total: totalCount.count,
      page: parseInt(page),
      limit: parseInt(limit),
      totalPages,
      hasNext: page < totalPages,
      hasPrev: page > 1
    });
  } catch (error) {
    console.error('💥 Error in podcasts endpoint:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch podcasts',
      details: error.message
    });
  }
}));

// Get podcast by ID
router.get('/:id', asyncHandler(async (req, res) => {
  try {
    const { id } = req.params;
    console.log('🔍 Podcast by ID endpoint called with ID:', id);
    
    const podcast = await db('podcasts')
      .where('id', id)
      .select(
        'id', 'title', 'title_somali', 'description', 'description_somali',
        'host', 'host_somali', 'language', 'cover_image_url', 'rss_feed_url',
        'website_url', 'total_episodes', 'rating', 'review_count',
        'is_featured', 'is_new_release', 'is_premium', 'is_free',
        'metadata', 'created_at', 'updated_at'
      )
      .first();

    if (!podcast) {
      console.log('❌ Podcast not found for ID:', id);
      return res.status(404).json({
        success: false,
        error: 'Podcast not found'
      });
    }

    console.log('✅ Podcast found:', {
      id: podcast.id,
      title: podcast.title,
      host: podcast.host
    });

    // Get categories for this podcast
    const categories = await db('podcast_categories')
      .join('categories', 'podcast_categories.category_id', 'categories.id')
      .where('podcast_categories.podcast_id', id)
      .where('categories.is_active', true)
      .select('categories.id', 'categories.name', 'categories.name_somali')
      .orderBy('categories.sort_order', 'asc');

    // Process podcast data
    const processedPodcast = {
      ...podcast,
      host: podcast.host || '',
      hostSomali: podcast.host_somali || '',
      categories: categories.map(cat => cat.id),
      categoryNames: categories.map(cat => cat.name),
      categoryNamesSomali: categories.map(cat => cat.name_somali),
      isFeatured: Boolean(podcast.is_featured),
      isNewRelease: Boolean(podcast.is_new_release),
      isPremium: Boolean(podcast.is_premium),
      isFree: Boolean(podcast.is_free),
      createdAt: podcast.created_at,
      updatedAt: podcast.updated_at,
    };

    console.log('🎙️ Returning podcast:', processedPodcast.title);

    res.json({
      success: true,
      podcast: processedPodcast
    });
  } catch (error) {
    console.error('💥 Error fetching podcast:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch podcast',
      details: error.message
    });
  }
}));

// Get podcast episodes/parts
router.get('/:id/episodes', asyncHandler(async (req, res) => {
  try {
    const { id } = req.params;
    const { page = 1, limit = 20, season } = req.query;
    const offset = (page - 1) * limit;
    
    console.log('🔍 Podcast episodes endpoint called for podcast:', id);

    let query = db('podcast_parts')
      .where('podcast_id', id)
      .select(
        'id', 'title', 'title_somali', 'description', 'description_somali',
        'episode_number', 'season_number', 'duration', 'audio_url',
        'transcript_url', 'transcript_content', 'show_notes', 'chapters',
        'rating', 'play_count', 'download_count', 'is_featured', 'is_premium',
        'is_free', 'published_at', 'metadata', 'created_at', 'updated_at'
      );

    // Apply season filter if provided
    if (season && season !== 'all') {
      query = query.where('season_number', season);
    }

    // Get total count
    let countQuery = db('podcast_parts').where('podcast_id', id);
    if (season && season !== 'all') {
      countQuery = countQuery.where('season_number', season);
    }
    const totalCount = await countQuery.count('* as count').first();
    const totalPages = Math.ceil(totalCount.count / limit);

    // Get episodes
    const episodes = await query
      .orderBy('episode_number', 'desc')
      .limit(limit)
      .offset(offset);

    console.log('🎧 Retrieved episodes:', episodes.length);

    // Process episodes
    const processedEpisodes = episodes.map(episode => ({
      id: episode.id,
      title: episode.title,
      titleSomali: episode.title_somali,
      description: episode.description,
      descriptionSomali: episode.description_somali,
      episodeNumber: episode.episode_number,
      seasonNumber: episode.season_number,
      duration: episode.duration,
      audioUrl: episode.audio_url,
      transcriptUrl: episode.transcript_url,
      transcriptContent: episode.transcript_content,
      showNotes: episode.show_notes,
      chapters: episode.chapters,
      rating: episode.rating,
      playCount: episode.play_count,
      downloadCount: episode.download_count,
      isFeatured: Boolean(episode.is_featured),
      isPremium: Boolean(episode.is_premium),
      isFree: Boolean(episode.is_free),
      publishedAt: episode.published_at,
      metadata: episode.metadata,
      createdAt: episode.created_at,
      updatedAt: episode.updated_at,
    }));

    res.json({
      success: true,
      episodes: processedEpisodes,
      total: totalCount.count,
      page: parseInt(page),
      limit: parseInt(limit),
      totalPages,
      hasNext: page < totalPages,
      hasPrev: page > 1
    });
  } catch (error) {
    console.error('💥 Error fetching podcast episodes:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch podcast episodes',
      details: error.message
    });
  }
}));

// Get featured podcasts
router.get('/featured/list', asyncHandler(async (req, res) => {
  try {
    const { limit = 10 } = req.query;
    console.log('🔍 Featured podcasts endpoint called with limit:', limit);

    const podcasts = await db('podcasts')
      .where('is_featured', true)
      .select(
        'id', 'title', 'title_somali', 'description', 'description_somali',
        'host', 'host_somali', 'language', 'cover_image_url', 'rss_feed_url',
        'website_url', 'total_episodes', 'rating', 'review_count',
        'is_featured', 'is_new_release', 'is_premium', 'is_free',
        'metadata', 'created_at', 'updated_at'
      )
      .orderBy('created_at', 'desc')
      .limit(parseInt(limit));

    console.log('⭐ Retrieved featured podcasts:', podcasts.length);

    // Process podcasts to include categories
    const processedPodcasts = await Promise.all(podcasts.map(async (podcast) => {
      const categories = await db('podcast_categories')
        .join('categories', 'podcast_categories.category_id', 'categories.id')
        .where('podcast_categories.podcast_id', podcast.id)
        .where('categories.is_active', true)
        .select('categories.id', 'categories.name', 'categories.name_somali')
        .orderBy('categories.sort_order', 'asc');

      return {
        id: podcast.id,
        title: podcast.title,
        titleSomali: podcast.title_somali,
        description: podcast.description,
        descriptionSomali: podcast.description_somali,
        host: podcast.host || '',
        hostSomali: podcast.host_somali || '',
        language: podcast.language,
        coverImageUrl: podcast.cover_image_url,
        rssFeedUrl: podcast.rss_feed_url,
        websiteUrl: podcast.website_url,
        totalEpisodes: podcast.total_episodes,
        rating: podcast.rating,
        reviewCount: podcast.review_count,
        isFeatured: Boolean(podcast.is_featured),
        isNewRelease: Boolean(podcast.is_new_release),
        isPremium: Boolean(podcast.is_premium),
        isFree: Boolean(podcast.is_free),
        metadata: podcast.metadata,
        createdAt: podcast.created_at,
        updatedAt: podcast.updated_at,
        categories: categories.map(cat => cat.id),
        categoryNames: categories.map(cat => cat.name),
        categoryNamesSomali: categories.map(cat => cat.name_somali),
      };
    }));

    res.json({
      success: true,
      featuredPodcasts: processedPodcasts
    });
  } catch (error) {
    console.error('💥 Error fetching featured podcasts:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch featured podcasts',
      details: error.message
    });
  }
}));

// Get new release podcasts
router.get('/new-releases/list', asyncHandler(async (req, res) => {
  try {
    const { limit = 10 } = req.query;
    console.log('🔍 New release podcasts endpoint called with limit:', limit);

    const podcasts = await db('podcasts')
      .where('is_new_release', true)
      .select(
        'id', 'title', 'title_somali', 'description', 'description_somali',
        'host', 'host_somali', 'language', 'cover_image_url', 'rss_feed_url',
        'website_url', 'total_episodes', 'rating', 'review_count',
        'is_featured', 'is_new_release', 'is_premium', 'is_free',
        'metadata', 'created_at', 'updated_at'
      )
      .orderBy('created_at', 'desc')
      .limit(parseInt(limit));

    console.log('🆕 Retrieved new release podcasts:', podcasts.length);

    // Process podcasts to include categories
    const processedPodcasts = await Promise.all(podcasts.map(async (podcast) => {
      const categories = await db('podcast_categories')
        .join('categories', 'podcast_categories.category_id', 'categories.id')
        .where('podcast_categories.podcast_id', podcast.id)
        .where('categories.is_active', true)
        .select('categories.id', 'categories.name', 'categories.name_somali')
        .orderBy('categories.sort_order', 'asc');

      return {
        id: podcast.id,
        title: podcast.title,
        titleSomali: podcast.title_somali,
        description: podcast.description,
        descriptionSomali: podcast.description_somali,
        host: podcast.host || '',
        hostSomali: podcast.host_somali || '',
        language: podcast.language,
        coverImageUrl: podcast.cover_image_url,
        rssFeedUrl: podcast.rss_feed_url,
        websiteUrl: podcast.website_url,
        totalEpisodes: podcast.total_episodes,
        rating: podcast.rating,
        reviewCount: podcast.review_count,
        isFeatured: Boolean(podcast.is_featured),
        isNewRelease: Boolean(podcast.is_new_release),
        isPremium: Boolean(podcast.is_premium),
        isFree: Boolean(podcast.is_free),
        metadata: podcast.metadata,
        createdAt: podcast.created_at,
        updatedAt: podcast.updated_at,
        categories: categories.map(cat => cat.id),
        categoryNames: categories.map(cat => cat.name),
        categoryNamesSomali: categories.map(cat => cat.name_somali),
      };
    }));

    res.json({
      success: true,
      newReleasePodcasts: processedPodcasts
    });
  } catch (error) {
    console.error('💥 Error fetching new release podcasts:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch new release podcasts',
      details: error.message
    });
  }
}));

// Get recent podcasts
router.get('/recent/list', asyncHandler(async (req, res) => {
  try {
    const { limit = 10 } = req.query;
    console.log('🔍 Recent podcasts endpoint called with limit:', limit);

    const podcasts = await db('podcasts')
      .select(
        'id', 'title', 'title_somali', 'description', 'description_somali',
        'host', 'host_somali', 'language', 'cover_image_url', 'rss_feed_url',
        'website_url', 'total_episodes', 'rating', 'review_count',
        'is_featured', 'is_new_release', 'is_premium', 'is_free',
        'metadata', 'created_at', 'updated_at'
      )
      .orderBy('created_at', 'desc')
      .limit(parseInt(limit));

    console.log('📅 Retrieved recent podcasts:', podcasts.length);

    // Process podcasts to include categories
    const processedPodcasts = await Promise.all(podcasts.map(async (podcast) => {
      const categories = await db('podcast_categories')
        .join('categories', 'podcast_categories.category_id', 'categories.id')
        .where('podcast_categories.podcast_id', podcast.id)
        .where('categories.is_active', true)
        .select('categories.id', 'categories.name', 'categories.name_somali')
        .orderBy('categories.sort_order', 'asc');

      return {
        id: podcast.id,
        title: podcast.title,
        titleSomali: podcast.title_somali,
        description: podcast.description,
        descriptionSomali: podcast.description_somali,
        host: podcast.host || '',
        hostSomali: podcast.host_somali || '',
        language: podcast.language,
        coverImageUrl: podcast.cover_image_url,
        rssFeedUrl: podcast.rss_feed_url,
        websiteUrl: podcast.website_url,
        totalEpisodes: podcast.total_episodes,
        rating: podcast.rating,
        reviewCount: podcast.review_count,
        isFeatured: Boolean(podcast.is_featured),
        isNewRelease: Boolean(podcast.is_new_release),
        isPremium: Boolean(podcast.is_premium),
        isFree: Boolean(podcast.is_free),
        metadata: podcast.metadata,
        createdAt: podcast.created_at,
        updatedAt: podcast.updated_at,
        categories: categories.map(cat => cat.id),
        categoryNames: categories.map(cat => cat.name),
        categoryNamesSomali: categories.map(cat => cat.name_somali),
      };
    }));

    res.json({
      success: true,
      recentPodcasts: processedPodcasts
    });
  } catch (error) {
    console.error('💥 Error fetching recent podcasts:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch recent podcasts',
      details: error.message
    });
  }
}));

// Get free podcasts
router.get('/free/list', asyncHandler(async (req, res) => {
  try {
    const { limit = 10 } = req.query;
    console.log('🔍 Free podcasts endpoint called with limit:', limit);

    const podcasts = await db('podcasts')
      .where('is_free', true)
      .select(
        'id', 'title', 'title_somali', 'description', 'description_somali',
        'host', 'host_somali', 'language', 'cover_image_url', 'rss_feed_url',
        'website_url', 'total_episodes', 'rating', 'review_count',
        'is_featured', 'is_new_release', 'is_premium', 'is_free',
        'metadata', 'created_at', 'updated_at'
      )
      .orderBy('created_at', 'desc')
      .limit(parseInt(limit));

    console.log('🆓 Retrieved free podcasts:', podcasts.length);

    // Process podcasts to include categories
    const processedPodcasts = await Promise.all(podcasts.map(async (podcast) => {
      const categories = await db('podcast_categories')
        .join('categories', 'podcast_categories.category_id', 'categories.id')
        .where('podcast_categories.podcast_id', podcast.id)
        .where('categories.is_active', true)
        .select('categories.id', 'categories.name', 'categories.name_somali')
        .orderBy('categories.sort_order', 'asc');

      return {
        id: podcast.id,
        title: podcast.title,
        titleSomali: podcast.title_somali,
        description: podcast.description,
        descriptionSomali: podcast.description_somali,
        host: podcast.host || '',
        hostSomali: podcast.host_somali || '',
        language: podcast.language,
        coverImageUrl: podcast.cover_image_url,
        rssFeedUrl: podcast.rss_feed_url,
        websiteUrl: podcast.website_url,
        totalEpisodes: podcast.total_episodes,
        rating: podcast.rating,
        reviewCount: podcast.review_count,
        isFeatured: Boolean(podcast.is_featured),
        isNewRelease: Boolean(podcast.is_new_release),
        isPremium: Boolean(podcast.is_premium),
        isFree: Boolean(podcast.is_free),
        metadata: podcast.metadata,
        createdAt: podcast.created_at,
        updatedAt: podcast.updated_at,
        categories: categories.map(cat => cat.id),
        categoryNames: categories.map(cat => cat.name),
        categoryNamesSomali: categories.map(cat => cat.name_somali),
      };
    }));

    res.json({
      success: true,
      freePodcasts: processedPodcasts
    });
  } catch (error) {
    console.error('💥 Error fetching free podcasts:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch free podcasts',
      details: error.message
    });
  }
}));

// Get random podcasts (for recommendations)
router.get('/random/list', asyncHandler(async (req, res) => {
  try {
    const { limit = 10 } = req.query;
    console.log('🔍 Random podcasts endpoint called with limit:', limit);

    const podcasts = await db('podcasts')
      .select(
        'id', 'title', 'title_somali', 'description', 'description_somali',
        'host', 'host_somali', 'language', 'cover_image_url', 'rss_feed_url',
        'website_url', 'total_episodes', 'rating', 'review_count',
        'is_featured', 'is_new_release', 'is_premium', 'is_free',
        'metadata', 'created_at', 'updated_at'
      )
      .orderByRaw('RAND()')
      .limit(parseInt(limit));

    console.log('🎲 Retrieved random podcasts:', podcasts.length);

    // Process podcasts to include categories
    const processedPodcasts = await Promise.all(podcasts.map(async (podcast) => {
      const categories = await db('podcast_categories')
        .join('categories', 'podcast_categories.category_id', 'categories.id')
        .where('podcast_categories.podcast_id', podcast.id)
        .where('categories.is_active', true)
        .select('categories.id', 'categories.name', 'categories.name_somali')
        .orderBy('categories.sort_order', 'asc');

      return {
        id: podcast.id,
        title: podcast.title,
        titleSomali: podcast.title_somali,
        description: podcast.description,
        descriptionSomali: podcast.description_somali,
        host: podcast.host || '',
        hostSomali: podcast.host_somali || '',
        language: podcast.language,
        coverImageUrl: podcast.cover_image_url,
        rssFeedUrl: podcast.rss_feed_url,
        websiteUrl: podcast.website_url,
        totalEpisodes: podcast.total_episodes,
        rating: podcast.rating,
        reviewCount: podcast.review_count,
        isFeatured: Boolean(podcast.is_featured),
        isNewRelease: Boolean(podcast.is_new_release),
        isPremium: Boolean(podcast.is_premium),
        isFree: Boolean(podcast.is_free),
        metadata: podcast.metadata,
        createdAt: podcast.created_at,
        updatedAt: podcast.updated_at,
        categories: categories.map(cat => cat.id),
        categoryNames: categories.map(cat => cat.name),
        categoryNamesSomali: categories.map(cat => cat.name_somali),
      };
    }));

    res.json({
      success: true,
      randomPodcasts: processedPodcasts
    });
  } catch (error) {
    console.error('💥 Error fetching random podcasts:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch random podcasts',
      details: error.message
    });
  }
}));

// Get podcast statistics
router.get('/stats', asyncHandler(async (req, res) => {
  try {
    // Total podcasts
    const totalPodcasts = await db('podcasts')
      .count('* as count')
      .first();
    
    // Featured podcasts
    const featuredPodcasts = await db('podcasts')
      .where('is_featured', true)
      .count('* as count')
      .first();
    
    // New releases
    const newReleases = await db('podcasts')
      .where('is_new_release', true)
      .count('* as count')
      .first();
    
    // Premium podcasts
    const premiumPodcasts = await db('podcasts')
      .where('is_premium', true)
      .count('* as count')
      .first();
    
    // Total episodes
    const totalEpisodes = await db('podcast_parts')
      .count('* as count')
      .first();
    
    // Podcasts by language
    const podcastsByLanguage = await db('podcasts')
      .select('language')
      .count('* as count')
      .groupBy('language');
    
    const languageStats = {};
    podcastsByLanguage.forEach(item => {
      languageStats[item.language] = parseInt(item.count);
    });
    
    // Average rating
    const avgRating = await db('podcasts')
      .whereNotNull('rating')
      .avg('rating as average')
      .first();
    
    res.json({
      success: true,
      stats: {
        totalPodcasts: totalPodcasts.count,
        featuredPodcasts: featuredPodcasts.count,
        newReleases: newReleases.count,
        premiumPodcasts: premiumPodcasts.count,
        totalEpisodes: totalEpisodes.count,
        averageRating: parseFloat(avgRating.average || 0).toFixed(2),
        podcastsByLanguage: languageStats
      }
    });
    
  } catch (error) {
    logger.error('Error fetching podcast statistics:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch podcast statistics',
      code: 'STATS_ERROR'
    });
  }
}));

module.exports = router;
