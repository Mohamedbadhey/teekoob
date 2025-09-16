import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teekoob/core/models/book_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:teekoob/features/player/services/audio_state_manager.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui;

class BookReadPage extends StatefulWidget {
  const BookReadPage({super.key});

  @override
  State<BookReadPage> createState() => _BookReadPageState();
}

class _BookReadPageState extends State<BookReadPage> {
  Book? _book;
  String? _pdfUrl;
  bool _showPdfContent = false;
  
  // Track registered view types to avoid duplicate registration
  static final Set<String> _registeredViewTypes = {};

  @override
  void initState() {
    super.initState();
    _loadPdfContent();
    // Automatically show PDF content
    _showPdfContent = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _book = GoRouterState.of(context).extra as Book?;
    _loadPdfContent();
  }

  void _loadPdfContent() {
    print('🔍 BookReadPage: _loadPdfContent called');
    print('📚 BookReadPage: _book is null: ${_book == null}');
    
    if (_book != null) {
      print('🔍 BookReadPage: Loading PDF content...');
      print('📚 BookReadPage: Book data: $_book');
      
      final ebookUrl = _book!.ebookUrl;
      print('🔗 BookReadPage: ebookUrl: $ebookUrl');
      print('🔗 BookReadPage: ebookUrl type: ${ebookUrl.runtimeType}');
      print('🔗 BookReadPage: ebookUrl is null: ${ebookUrl == null}');
      print('🔗 BookReadPage: ebookUrl is empty: ${ebookUrl?.isEmpty}');
      
      if (ebookUrl != null && ebookUrl.isNotEmpty) {
        print('✅ BookReadPage: PDF found, loading content...');
        print('📄 BookReadPage: Raw ebookUrl: $ebookUrl');
        print('📄 BookReadPage: ebookUrl type: ${ebookUrl.runtimeType}');
        
        // For web, we'll use the full URL
        if (kIsWeb) {
          _pdfUrl = 'http://localhost:3000$ebookUrl';
          print('🔗 BookReadPage: PDF URL ready: $_pdfUrl');
          print('🌐 BookReadPage: Running on web - kIsWeb: $kIsWeb');
          
          // Test if URL is accessible
          js.context.callMethod('eval', ['''
            console.log('🔍 Testing PDF URL accessibility');
            fetch('$_pdfUrl')
              .then(response => {
                console.log('✅ PDF URL response:', response);
                console.log('✅ PDF URL status:', response.status);
                console.log('✅ PDF URL headers:', response.headers);
              })
              .catch(error => {
                console.error('❌ PDF URL error:', error);
              });
          ''']);
        } else {
          // For mobile, we'll use the relative path
          _pdfUrl = ebookUrl;
          print('📱 BookReadPage: PDF path ready: $_pdfUrl');
          print('📱 BookReadPage: Running on mobile - kIsWeb: $kIsWeb');
        }
        
        setState(() {
          print('🔄 BookReadPage: setState called - _pdfUrl updated to: $_pdfUrl');
        });
      } else {
        print('❌ BookReadPage: No PDF URL found');
        setState(() {
          _pdfUrl = null;
          print('🔄 BookReadPage: setState called - _pdfUrl set to null');
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
        color: Color(0xFFF56C23), // Orange - same as home page top bar
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white, // White text on orange background
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
              color: const Color(0xFFF56C23), // Orange - same as home page
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
    print('🔗 _buildEbookContent: _pdfUrl: $_pdfUrl');
    print('📱 _buildEbookContent: kIsWeb: $kIsWeb');
    print('📚 _buildEbookContent: book.title: ${book.title}');
    print('📄 _buildEbookContent: book.ebookUrl: ${book.ebookUrl}');
    
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
          child: _pdfUrl == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.book_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No ebook content available for this book.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : _buildPdfViewer(context, book),
        ),
      ],
    );
  }

  Widget _buildPdfOpener() {
    // Automatically trigger PDF viewing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewPdfInApp();
    });
    
    // Show loading indicator while PDF loads
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF56C23)),
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

  void _openPdfInNewTab() {
    if (_pdfUrl != null) {
      // For web, open PDF directly in the browser
      print('Opening PDF directly: $_pdfUrl');
      if (kIsWeb) {
        // Use dart:html to open PDF in new tab
        html.window.open(_pdfUrl!, '_blank');
      } else {
        // For mobile, show a message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF content not available for mobile viewing.')),
        );
      }
    }
  }

  void _viewPdfInApp() {
    print('🎯 _viewPdfInApp: Called');
    print('🔗 _viewPdfInApp: _pdfUrl: $_pdfUrl');
    print('📱 _viewPdfInApp: kIsWeb: $kIsWeb');
    print('🔄 _viewPdfInApp: Current _showPdfContent: $_showPdfContent');
    
    if (_pdfUrl != null) {
      print('✅ _viewPdfInApp: PDF URL available, setting _showPdfContent to true');
      setState(() {
        _showPdfContent = true;
        print('🔄 _viewPdfInApp: setState called - _showPdfContent set to true');
      });
    } else {
      print('❌ _viewPdfInApp: No PDF URL available');
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
    print('🔗 _buildPdfFrame: Creating PDF frame');
    print('🔗 _buildPdfFrame: PDF URL: $_pdfUrl');
    print('🔗 _buildPdfFrame: Running on web: $kIsWeb');
    
    if (kIsWeb && _pdfUrl != null) {
      // Create a unique ID for this PDF viewer
      final String elementId = 'pdf-viewer-${_pdfUrl!.hashCode}';
      print('🔗 _buildPdfFrame: Element ID: $elementId');
      
      // Register the view factory if not already registered
      if (!_registeredViewTypes.contains(elementId)) {
        print('🔧 _buildPdfFrame: Registering view factory for $elementId');
        // Register the view factory
        ui.platformViewRegistry.registerViewFactory(elementId, (int viewId) {
          print('🔧 View factory called for $elementId with viewId: $viewId');
          
          // Create a container div for custom styling
          final container = html.DivElement()
            ..id = elementId
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.overflow = 'hidden'
            ..style.backgroundColor = 'white'
            ..style.position = 'relative';

          // Create the iframe with custom styling
          final iframe = html.IFrameElement()
            ..src = _pdfUrl!
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.border = 'none'
            ..style.position = 'absolute'
            ..style.top = '0'
            ..style.left = '0'
            ..style.right = '0'
            ..style.bottom = '0'
            ..style.overflow = 'hidden'
            ..setAttribute('type', 'application/pdf')
            ..setAttribute('frameborder', '0')
            ..setAttribute('scrolling', 'auto');

          // Add custom CSS to hide toolbar and other controls
          final style = html.StyleElement()
            ..text = '''
              @media screen {
                #${elementId} {
                  overflow: hidden !important;
                  border-radius: 8px;
                }
                #${elementId} iframe {
                  width: 100% !important;
                  height: 100% !important;
                  border: none !important;
                }
                /* Hide toolbar and other controls */
                #${elementId} iframe + div,
                #${elementId} .toolbar,
                #${elementId} #toolbarContainer,
                #${elementId} #toolbarViewer,
                #${elementId} #secondaryToolbar,
                #${elementId} .findbar,
                #${elementId} .secondaryToolbar,
                #${elementId} #sidebarContainer,
                #${elementId} #overlayContainer,
                #${elementId} #printContainer,
                #${elementId} #download,
                #${elementId} #viewBookmark,
                #${elementId} #secondaryPresentationMode,
                #${elementId} #presentationMode,
                #${elementId} #openFile,
                #${elementId} #print,
                #${elementId} #download,
                #${elementId} #viewBookmark,
                #${elementId} .verticalToolbarSeparator,
                #${elementId} .horizontalToolbarSeparator,
                #${elementId} .findbar,
                #${elementId} .toolbar {
                  display: none !important;
                  visibility: hidden !important;
                  width: 0 !important;
                  height: 0 !important;
                  position: absolute !important;
                  top: -9999px !important;
                  left: -9999px !important;
                  z-index: -1 !important;
                }
                #${elementId} #viewerContainer {
                  top: 0 !important;
                  padding-top: 0 !important;
                }
              }
            ''';

          container.children.add(style);
          container.children.add(iframe);
          
          // Add JavaScript to further clean up the viewer
          js.context.callMethod('eval', ['''
            setTimeout(() => {
              const iframe = document.querySelector('#${elementId} iframe');
              if (iframe) {
                iframe.onload = () => {
                  const iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
                  if (iframeDoc) {
                    // Create and inject custom CSS
                    const style = iframeDoc.createElement('style');
                    style.textContent = `
                      #toolbarContainer, #toolbarViewer, #secondaryToolbar,
                      #sidebarContainer, #overlayContainer, #printContainer,
                      #download, #viewBookmark, .toolbar, .findbar,
                      .secondaryToolbar, .verticalToolbarSeparator,
                      .horizontalToolbarSeparator {
                        display: none !important;
                        visibility: hidden !important;
                      }
                      #viewerContainer {
                        top: 0 !important;
                        padding-top: 0 !important;
                      }
                      #viewer {
                        margin: 0 !important;
                        padding: 0 !important;
                      }
                      #viewer .page {
                        margin: 0 auto !important;
                        border: none !important;
                      }
                    `;
                    iframeDoc.head.appendChild(style);
                  }
                };
              }
            }, 100);
          ''']);
          
          return container;
            
          print('🔧 Created iframe with URL: $_pdfUrl');
          
          // Add event listeners
          iframe.onLoad.listen((event) {
            print('✅ Iframe loaded successfully');
          });
          
          iframe.onError.listen((event) {
            print('❌ Error loading iframe: $event');
          });
          
          container.children.add(iframe);
          return container;
        });
        _registeredViewTypes.add(elementId);
        print('✅ View factory registered for $elementId');
      } else {
        print('ℹ️ View factory already registered for $elementId');
      }

      print('🔗 _buildPdfFrame: Creating Flutter container with HtmlElementView');
      print('🔗 _buildPdfFrame: Using view type: $elementId');
      
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        clipBehavior: Clip.antiAlias,
        child: HtmlElementView(
          viewType: elementId,
          onPlatformViewCreated: (int id) {
            print('✅ HtmlElementView created with ID: $id');
            // Check if the element exists in DOM after view creation
            js.context.callMethod('eval', ['''
              console.log('🔍 Checking view after creation');
              var container = document.getElementById('$elementId');
              console.log('🔍 Container after view creation:', container);
              console.log('🔍 Iframe after view creation:', container ? container.querySelector('iframe') : null);
            ''']);
          },
        ),
      );
    } else {
      return Container(
        color: Colors.grey[100],
        child: const Center(
          child: Text('PDF frame not available'),
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
                backgroundColor: const Color(0xFFF56C23),
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



  void _downloadPdf() {
    if (_pdfUrl != null) {
      // For web, create a download link
      if (kIsWeb) {
        final anchor = html.AnchorElement(href: _pdfUrl!)
          ..setAttribute('download', '${_book?.title ?? 'book'}.pdf')
          ..click();
        // The anchor element is used for download functionality
      }
    }
  }
}

