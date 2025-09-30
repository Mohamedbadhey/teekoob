import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:teekoob/features/player/services/audio_state_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:teekoob/core/config/app_router.dart';

class BookReadPage extends StatefulWidget {
  const BookReadPage({super.key});

  @override
  State<BookReadPage> createState() => _BookReadPageState();
}

class _BookReadPageState extends State<BookReadPage> {
  Book? _book;
  String? _pdfUrl;
  bool _showPdfContent = false;

  @override
  void initState() {
    super.initState();
    _loadEbookContent();
    // Automatically show ebook content
    _showPdfContent = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _book = GoRouterState.of(context).extra as Book?;
    _loadEbookContent();
  }

  void _loadEbookContent() {
    print('🔍 BookReadPage: _loadEbookContent called');
    print('📚 BookReadPage: _book is null: ${_book == null}');
    
    if (_book != null) {
      print('🔍 BookReadPage: Loading ebook content...');
      print('📚 BookReadPage: Book data: $_book');
      
      final ebookContent = _book!.ebookContent;
      print('📖 BookReadPage: ebookContent type: ${ebookContent.runtimeType}');
      print('📖 BookReadPage: ebookContent is null: ${ebookContent == null}');
      print('📖 BookReadPage: ebookContent is empty: ${ebookContent?.isEmpty}');
      
      if (ebookContent != null && ebookContent.isNotEmpty) {
        print('✅ BookReadPage: Ebook content found, loading...');
        setState(() {
          _showPdfContent = true;
          print('🔄 BookReadPage: setState called - _showPdfContent set to true');
        });
      } else {
        print('❌ BookReadPage: No ebook content found');
        setState(() {
          _showPdfContent = false;
          print('🔄 BookReadPage: setState called - _showPdfContent set to false');
        });
      }
    } else {
      print('❌ BookReadPage: No book data available');
    }
  }

  String _getFallbackContent(Book book) {
    // This is where you would fetch the actual content from your database
    // For now, I'll provide dynamic content based on the book information
    
    if (book.language == 'so') {
      return '''
Hordhac: ${book.titleSomali ?? book.title}

Waxaa jirta ammin maalinta ka mid ah oo ay badi dadku hurdaan-saacad ku shareeran shibbanida, saacad ka caaggan sawaxanka caalamka, ilayska shaashadaha, iyo qalalasaaha nolosha. Waa ammin nabdoon asii awood badan.

Dadka leh kudbac ay ku kacaan 5-ta subaxnimo, waxay u tahay illinka dib isu-curinta. Kuma eka xeelad lagu kobcinayo waxsoosaarka, iyo habdhaqan uun-ee waxay noqotaa sidii caado barakaysan oo beddesha habfekerka, waxqabadka, iyo yoolka.

Waxaa isbeddelkan udubdhexaad u ah aragti la dhayalsado: sida aad ku billowdo maalintaada ayaa go'aamisa sida aad u noolaato noloshaada. Halka ay dadku badi subaxdii ku qaataan hantaaturro iyo falcelin, dadka dishibiliinka subixii la kacaa, waxay furaan irdaha dheef aan dadka kale u muuqqan.

Ma ahan keliya waqti dheeri ah oo usoo kordha, ee waa saafiinnimo, kelinnimo, iyo ujeeddo ay dhiif tahay inay helaan dadku.

Sheekadan waxaa tebinaya hal-abuure ganacsi oo soo jabay, iyo fannaan halgamaya, oo labadaba uu hagayo tababbare biliyaneer ah oo xerakabbood ah. Geeddigooda ayaa lagu soo dhex gudbinayaa caadooyinka Naadiga 5-ta Subaxnimo, mana aha xeerar qallafsan, ee waa falsafad nololeed oo ku salaysan dhisme, koboc iyo hanashada nafta.

Saacadaha hore ee maalintu waa aag looga bogsado hawllananta, lagu dhiso adkaysiga, isla markaana qofku kula xiriirro qudhiisa sare.

Inaad soo kacdo adduunka intiisa kale oo hurda, sida aad kaga bogan doonto Bookoob-kan, kuma ay siinayso oo keliya saacado dheeri-ee waxaad dib ugu hanataa dhimirkaaga. Adduunkan qabatimay orodka iyo sawaxanka, inaad si xasiilloon naftaada ugu talisaa waa noc ka mid xornimada.

${book.descriptionSomali ?? book.description ?? ''}

Nota: Waxaa la isku dayay in la soo saaro qoraalka PDF-ka, laakiin ma suurto gelin. Waxaan ku soo qaadnay qoraal ku habboon.
''';
    } else {
      return '''
Introduction: ${book.title}

There is a special moment in the day when most people are asleep, an hour connected to the dawn, an hour away from the world's noise, the light of the morning, and the beginning of life. It is a peaceful moment with great power.

For people who wake up at 5 AM, it is the link to self-renewal. There is no secret technique to increase productivity, and it is not just a habit - it becomes like a blessed tradition that changes mindset, action, and purpose.

This change is centered on a simple insight: how you start your day determines how you live your life. While most people spend their mornings in reaction and response, people who wake up at 5 AM open doors that are invisible to others.

It's not just extra time, it's clarity, focus, and purpose that people gain.

This story is told by a successful entrepreneur and a dedicated artist, both guided by a billionaire mentor who is very organized. Their journey takes them through the traditions of the 5 AM Club, and it's not strict rules, but a life philosophy based on structure, growth, and self-mastery.

The early hours of the day are a space to return to work, build resilience, and connect with your higher self.

When you wake up before the rest of the world, as you will learn from this book, it doesn't just give you extra hours - you regain control of your life. This world that has mastered speed and noise, to plan your life with peace is one of the freedoms.

${book.description ?? ''}

Note: We attempted to extract text from the PDF but were unable to. We've provided appropriate content instead.
''';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_book == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Book not found'),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, _book!),
            
            // Main Content
            Expanded(
              child: _buildEbookContent(context, _book!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Book book) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFF0466c8), // Blue - same as home page top bar
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: () => AppRouter.handleBackNavigation(context),
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24,
            ),
          ),
          
          // Title
          Expanded(
            child: Text(
              (book.titleSomali?.isNotEmpty ?? false) ? book.titleSomali! : book.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Spacer to maintain symmetry
          const SizedBox(width: 48), // Same width as back button
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Book book) {
    return Row(
      children: [
        // Listen Button
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF0466c8), // Blue - same as home page
              borderRadius: BorderRadius.circular(12),
            ),
            child: StreamBuilder<bool>(
              stream: AudioStateManager().isPlayingStream,
              builder: (context, snapshot) {
                final bool isPlaying = snapshot.data ?? false;
                final bool isCurrentBook = AudioStateManager().currentBook?.id == _book?.id;
                
                return TextButton.icon(
                  onPressed: () {
                    if (_book != null) {
                      if (isCurrentBook && isPlaying) {
                        AudioStateManager().pause();
                      } else {
                        AudioStateManager().playBook(_book!);
                        context.push('/home/player/${_book!.id}', extra: _book);
                      }
                    }
                  },
                  icon: Icon(
                    (isCurrentBook && isPlaying) ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  label: Text(
                    (isCurrentBook && isPlaying) ? 'Pause' : 'Listen',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Back to Home Button
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF1E3A8A), // Dark blue - same as home page
                width: 1.5,
              ),
            ),
            child: TextButton(
              onPressed: () {
                context.go('/home');
              },
              child: const Text(
                'Back to home',
                style: TextStyle(
                  color: const Color(0xFF1E3A8A), // Dark blue text
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEbookContent(BuildContext context, Book book) {
    print('📖 _buildEbookContent: Called');
    print('📱 _buildEbookContent: kIsWeb: $kIsWeb');
    print('📚 _buildEbookContent: book.title: ${book.title}');
    
    return Column(
      children: [
        // Action Buttons
        Container(
          padding: const EdgeInsets.all(20.0),
          child: _buildActionButtons(context, book),
        ),
        
        const SizedBox(height: 20),
        
        // Ebook Content
        Expanded(
          child: book.ebookContent == null || book.ebookContent!.isEmpty
              ? _buildFallbackContent(context, book)
              : _buildTextContentViewer(context, book),
        ),
      ],
    );
  }

  Widget _buildFallbackContent(BuildContext context, Book book) {
    return Center(
      child: Text(
        'There is no data',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTextContentViewer(BuildContext context, Book book) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Text(
            book.ebookContent!,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPdfOpener() {
    // Show loading indicator while PDF loads
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0466c8)),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
          ),
        ),
      ],
      ),
    );
  }

  void _openPdfInNewTab() async {
    if (_pdfUrl != null) {
      // For mobile, open PDF in external app
      print('Opening PDF directly: $_pdfUrl');
      try {
        final uri = Uri.parse(_pdfUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot open PDF. Please check your internet connection.'),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening PDF: $e'),
          ),
        );
      }
    }
  }


  Widget _buildPdfViewer(BuildContext context, Book book) {
    print('🏗️ _buildPdfViewer: Called');
    print('🔄 _buildPdfViewer: _showPdfContent: $_showPdfContent');
    print('🔗 _buildPdfViewer: _pdfUrl: $_pdfUrl');
    print('📱 _buildPdfViewer: kIsWeb: $kIsWeb');
    
    if (_showPdfContent) {
      print('✅ _buildPdfViewer: Showing PDF content viewer');
      // Show the actual PDF content inside the app
      return _buildPdfContentViewer();
    } else {
      print('📋 _buildPdfViewer: Showing PDF opener interface');
      // Show the PDF opener interface
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Column(
          children: [
            // Simple Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    color: Colors.red[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Reading: ${book.title ?? 'Book'}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _openPdfInNewTab(),
                    icon: const Icon(Icons.open_in_new),
                    tooltip: 'Open in New Tab',
                  ),
                ],
              ),
            ),
            
            // PDF Content Area
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildPdfOpener(),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPdfContentViewer() {
    // Show the actual PDF content inside the app
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          // PDF Viewer Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _showPdfContent = false),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back to Info',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reading: ${_book?.title ?? 'Book'}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _openPdfInNewTab(),
                  icon: const Icon(Icons.open_in_new),
                  tooltip: 'Open in New Tab',
                ),
              ],
            ),
          ),
          
          // PDF Content Area - ACTUAL PDF VIEWER
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildActualPdfContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _createPdfIframeElement() {
    // This will create the actual PDF iframe for web
    if (kIsWeb && _pdfUrl != null) {
      // For web, create a simple but effective PDF viewer
      return _buildSimplePdfViewer();
    } else {
      return Container(
        color: Colors.grey[100],
        child: const Center(
          child: Text('PDF iframe not available'),
        ),
      );
    }
  }

  Widget _buildSimplePdfViewer() {
    // Simple but effective PDF viewer that shows the actual PDF
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          // PDF Viewer Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  color: Colors.red[600],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'PDF Content',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  'File: ${_pdfUrl?.split('/').last ?? 'Unknown'}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // PDF Content Area - ACTUAL PDF VIEWER
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildPdfIframeContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActualPdfContent() {
    print('🔗 _buildActualPdfContent: Building actual PDF content');
    print('🔗 _buildActualPdfContent: _pdfUrl: $_pdfUrl');
    print('🔗 _buildActualPdfContent: kIsWeb: $kIsWeb');
    
    // Show the actual PDF content using an iframe
    if (kIsWeb && _pdfUrl != null) {
      print('✅ _buildActualPdfContent: Creating web PDF viewer');
      return _buildWebPdfViewer();
    } else {
      print('❌ _buildActualPdfContent: Not web or no PDF URL');
      return Container(
        color: Colors.grey[100],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.picture_as_pdf,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'PDF Viewer Not Available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please use the web version to view PDFs',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }



  Widget _buildRealPdfViewer() {
    // Real PDF viewer that shows the actual PDF content
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          // PDF Content Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  color: Colors.red[600],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'PDF Content',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  'File: ${_pdfUrl?.split('/').last ?? 'Unknown'}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // PDF Content Area - ACTUAL PDF VIEWER
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildPdfIframe(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfIframe() {
    // Create an iframe to display the PDF content
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: _buildPdfContent(),
    );
  }

  Widget _buildPdfContent() {
    // Show the actual PDF content
    if (kIsWeb && _pdfUrl != null) {
      return _buildWebPdfViewer();
    } else {
      return Container(
        color: Colors.grey[100],
        child: const Center(
          child: Text('PDF content not available'),
        ),
      );
    }
  }







  Widget _buildPdfIframeContent() {
    print('🔗 _buildPdfIframeContent: Creating PDF iframe content');
    print('🔗 _buildPdfIframeContent: _pdfUrl: $_pdfUrl');
    
    if (kIsWeb && _pdfUrl != null) {
      // For web, create a direct HTML iframe that shows the PDF
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Column(
          children: [
            // Header with PDF info
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: Row(
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    color: Colors.red[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'PDF: ${_pdfUrl!.split('/').last}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    'Loading PDF...',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // PDF iframe content
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: _buildDirectHtmlIframe(),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        color: Colors.grey[100],
        child: const Center(
          child: Text('PDF viewer not available for this platform'),
        ),
      );
    }
  }

  Widget _buildDirectHtmlIframe() {
    print('🔗 _buildDirectHtmlIframe: Creating advanced PDF viewer');
    print('🔗 _buildDirectHtmlIframe: _pdfUrl: $_pdfUrl');
    
    if (kIsWeb && _pdfUrl != null) {
      // For web, use WebView to display PDF
      return _buildWebPdfViewer();
    } else if (!kIsWeb && _pdfUrl != null) {
      // For mobile, use flutter_pdfview
      return _buildMobilePdfViewer();
    } else {
      return Container(
        color: Colors.grey[100],
        child: const Center(
          child: Text('PDF viewer not available for this platform'),
        ),
      );
    }
  }

  Widget _buildWebPdfViewer() {
    print('🔗 _buildWebPdfViewer: Creating web PDF viewer');
    print('🔗 _buildWebPdfViewer: PDF URL: $_pdfUrl');
    
    if (kIsWeb && _pdfUrl != null) {
      // Create a container for the PDF viewer
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Column(
          children: [
            // PDF Viewer Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: Row(
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    color: Colors.red[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Reading: ${_book?.title ?? 'PDF'}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _openPdfInNewTab(),
                    icon: const Icon(Icons.open_in_new),
                    tooltip: 'Open in New Tab',
                  ),
                ],
              ),
            ),
            
            // PDF Content Area
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildPdfFrame(),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        color: Colors.grey[100],
        child: const Center(
          child: Text('PDF viewer not available'),
        ),
      );
    }
  }

  Widget _buildPdfFrame() {
    print('🔗 _buildPdfFrame: Creating PDF frame for mobile');
    print('🔗 _buildPdfFrame: PDF URL: $_pdfUrl');
    
    if (_pdfUrl != null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            // PDF Viewer Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    color: Colors.red[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PDF Viewer',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Tap to open in external app',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _openPdfInNewTab,
                    icon: const Icon(Icons.open_in_new),
                    tooltip: 'Open in external app',
                  ),
                ],
              ),
            ),
            // PDF Preview Area
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      size: 80,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'PDF Document',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the button below to open the PDF',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _viewPdfInApp,
                      icon: const Icon(Icons.visibility),
                      label: const Text('View in App'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _openPdfInNewTab,
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('External'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _downloadPdf,
                          icon: const Icon(Icons.download),
                          label: const Text('Download'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        color: Colors.grey[100],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'PDF not available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildMobilePdfViewer() {
    print('🔗 _buildMobilePdfViewer: Creating mobile PDF viewer');
    
    // For mobile, we need to download the PDF first
    // For now, show a message and provide download option
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf,
              size: 80,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'PDF Viewer for Mobile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'PDF URL: $_pdfUrl',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openPdfInNewTab(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0466c8),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open PDF'),
            ),
            const SizedBox(height: 16),
            Text(
              'Mobile PDF viewer requires PDF download.\nUse the button above to view.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }



  void _downloadPdf() async {
    if (_pdfUrl != null) {
      // For mobile, open PDF in external app (which can be downloaded)
      try {
        final uri = Uri.parse(_pdfUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot open PDF for download. Please check your internet connection.'),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening PDF: $e'),
          ),
        );
      }
    }
  }

  void _viewPdfInApp() {
    if (_pdfUrl != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _PdfViewerPage(pdfUrl: _pdfUrl!),
        ),
      );
    }
  }
}

// PDF Viewer Page using WebView
class _PdfViewerPage extends StatefulWidget {
  final String pdfUrl;

  const _PdfViewerPage({required this.pdfUrl});

  @override
  State<_PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<_PdfViewerPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController();
    
    // Only set JavaScript mode on mobile platforms
    if (!kIsWeb) {
      _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    }
    
    _controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String url) {
          setState(() {
            _isLoading = true;
            _error = null;
          });
        },
        onPageFinished: (String url) {
          setState(() {
            _isLoading = false;
          });
        },
        onWebResourceError: (WebResourceError error) {
          setState(() {
            _isLoading = false;
            _error = 'Failed to load PDF: ${error.description}';
          });
        },
      ),
    );
    
    _controller.loadRequest(Uri.parse(widget.pdfUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () async {
              final uri = Uri.parse(widget.pdfUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Open in external app',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_error != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error Loading PDF',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _isLoading = true;
                      });
                      _initializeWebView();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          else
            WebViewWidget(controller: _controller),
          if (_isLoading && _error == null)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading PDF...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

