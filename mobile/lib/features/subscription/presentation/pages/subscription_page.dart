import 'package:flutter/material.dart';
import 'package:teekoob/core/services/localization_service.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  String _selectedPlan = 'monthly';
  bool _isSubscribed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService.getLocalizedText(
          englishText: 'Subscription',
          somaliText: 'Diiwaangelinta',
        )),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Current Status
            _buildCurrentStatus(),
            
            const SizedBox(height: 24),
            
            // Subscription Plans
            _buildSubscriptionPlans(),
            
            const SizedBox(height: 24),
            
            // Features
            _buildFeatures(),
            
            const SizedBox(height: 24),
            
            // FAQ
            _buildFAQ(),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatus() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            _isSubscribed ? Icons.check_circle : Icons.star,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            _isSubscribed
                ? LocalizationService.getLocalizedText(
                    englishText: 'Premium Member',
                    somaliText: 'Xubno Premium',
                  )
                : LocalizationService.getLocalizedText(
                    englishText: 'Free Plan',
                    somaliText: 'Qorshe Bilaash',
                  ),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSubscribed
                ? LocalizationService.getLocalizedText(
                    englishText: 'Enjoy unlimited access to all content',
                    somaliText: 'Ku raaxayso helitaanka aan xadidnayn',
                  )
                : LocalizationService.getLocalizedText(
                    englishText: 'Upgrade to unlock premium features',
                    somaliText: 'Kor u qaad si aad u furtid aaladaha premium',
                  ),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionPlans() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocalizationService.getLocalizedText(
              englishText: 'Choose Your Plan',
              somaliText: 'Dooro Qorshekaaga',
            ),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Monthly Plan
          _buildPlanCard(
            title: LocalizationService.getLocalizedText(
              englishText: 'Monthly',
              somaliText: 'Bilka',
            ),
            price: '\$9.99',
            period: LocalizationService.getLocalizedText(
              englishText: 'per month',
              somaliText: 'bil kasta',
            ),
            isSelected: _selectedPlan == 'monthly',
            onTap: () => setState(() => _selectedPlan = 'monthly'),
            isPopular: false,
          ),
          
          const SizedBox(height: 12),
          
          // Annual Plan
          _buildPlanCard(
            title: LocalizationService.getLocalizedText(
              englishText: 'Annual',
              somaliText: 'Sanadka',
            ),
            price: '\$99.99',
            period: LocalizationService.getLocalizedText(
              englishText: 'per year',
              somaliText: 'sanad kasta',
            ),
            isSelected: _selectedPlan == 'annual',
            onTap: () => setState(() => _selectedPlan = 'annual'),
            isPopular: true,
            savings: LocalizationService.getLocalizedText(
              englishText: 'Save 17%',
              somaliText: 'Keydi 17%',
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Subscribe Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubscribed ? null : _handleSubscribe,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isSubscribed
                    ? LocalizationService.getLocalizedText(
                        englishText: 'Already Subscribed',
                        somaliText: 'Horey u diiwaangelisay',
                      )
                    : LocalizationService.getLocalizedText(
                        englishText: 'Subscribe Now',
                        somaliText: 'Hadda Diiwaangelin',
                      ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isPopular,
    String? savings,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surface,
        ),
        child: Stack(
          children: [
            if (isPopular)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    LocalizationService.getLocalizedText(
                      englishText: 'BEST VALUE',
                      somaliText: 'QIIMO UGU WANAGSAN',
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      period,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                if (savings != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    savings,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatures() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocalizationService.getLocalizedText(
              englishText: 'Premium Features',
              somaliText: 'Aaladaha Premium',
            ),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildFeatureItem(
            icon: Icons.book,
            title: LocalizationService.getLocalizedText(
              englishText: 'Unlimited Books',
              somaliText: 'Kutub Aan Xadidnayn',
            ),
            description: LocalizationService.getLocalizedText(
              englishText: 'Access to our entire library',
              somaliText: 'Helitaanka maktabadeena oo dhan',
            ),
          ),
          
          _buildFeatureItem(
            icon: Icons.headphones,
            title: LocalizationService.getLocalizedText(
              englishText: 'Audiobooks',
              somaliText: 'Kutubta Codka',
            ),
            description: LocalizationService.getLocalizedText(
              englishText: 'Listen to books on the go',
              somaliText: 'Dhegayso kutubta safarka',
            ),
          ),
          
          _buildFeatureItem(
            icon: Icons.download,
            title: LocalizationService.getLocalizedText(
              englishText: 'Offline Reading',
              somaliText: 'Akhrin Offline',
            ),
            description: LocalizationService.getLocalizedText(
              englishText: 'Download books for offline access',
              somaliText: 'Soo deji kutubta helitaanka offline',
            ),
          ),
          
          _buildFeatureItem(
            icon: Icons.devices,
            title: LocalizationService.getLocalizedText(
              englishText: 'Multi-Device Sync',
              somaliText: 'Isku Xidhka Alaabo Badan',
            ),
            description: LocalizationService.getLocalizedText(
              englishText: 'Sync your progress across devices',
              somaliText: 'Isku xidh horumarkaaga alaabo kasta',
            ),
          ),
          
          _buildFeatureItem(
            icon: Icons.priority_high,
            title: LocalizationService.getLocalizedText(
              englishText: 'Priority Support',
              somaliText: 'Taageero Mudan',
            ),
            description: LocalizationService.getLocalizedText(
              englishText: 'Get help when you need it most',
              somaliText: 'Hel caawimaad marka aad u baahan tahay',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQ() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocalizationService.getLocalizedText(
              englishText: 'Frequently Asked Questions',
              somaliText: 'Su\'aalaha Inta Badan La Isweydiiyo',
            ),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildFAQItem(
            question: LocalizationService.getLocalizedText(
              englishText: 'Can I cancel anytime?',
              somaliText: 'Ma dhici karaa inaan joojiyo wakhti kasta?',
            ),
            answer: LocalizationService.getLocalizedText(
              englishText: 'Yes, you can cancel your subscription at any time. Your access will continue until the end of your current billing period.',
              somaliText: 'Haa, waxaad joojin kartaa diiwaangelintaaga wakhti kasta. Helitaankaaga wuxuu sii wadi doonaa ilaa dhamaadka mudada bixin.',
            ),
          ),
          
          _buildFAQItem(
            question: LocalizationService.getLocalizedText(
              englishText: 'What payment methods do you accept?',
              somaliText: 'Habka bixin ee aad aqbashaan maa?',
            ),
            answer: LocalizationService.getLocalizedText(
              englishText: 'We accept all major credit cards, debit cards, and PayPal. All payments are secure and encrypted.',
              somaliText: 'Waxaan aqbalnaa dhammaan kaarka kareedka, kaarka debitka, iyo PayPal. Dhammaan bixinta waa amni ah oo la xifdiyey.',
            ),
          ),
          
          _buildFAQItem(
            question: LocalizationService.getLocalizedText(
              englishText: 'Is there a free trial?',
              somaliText: 'Ma jiraa tijaabo bilaash ah?',
            ),
            answer: LocalizationService.getLocalizedText(
              englishText: 'Yes, we offer a 7-day free trial for new subscribers. You can cancel anytime during the trial period.',
              somaliText: 'Haa, waxaan bixinaa tijaabo 7 maalmood ah oo bilaash ah xubnaha cusub. Waxaad joojin kartaa wakhti kasta mudada tijaabada.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return ExpansionTile(
      title: Text(
        question,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }

  void _handleSubscribe() {
    // TODO: Implement subscription logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.getLocalizedText(
          englishText: 'Coming Soon',
          somaliText: 'Dhawaan',
        )),
        content: Text(LocalizationService.getLocalizedText(
          englishText: 'Subscription functionality will be implemented soon!',
          somaliText: 'Aalada diiwaangelinta waxay dhawaan la hirgelin doonaa!',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LocalizationService.getLocalizedText(
              englishText: 'OK',
              somaliText: 'Hagaag',
            )),
          ),
        ],
      ),
    );
  }
}
