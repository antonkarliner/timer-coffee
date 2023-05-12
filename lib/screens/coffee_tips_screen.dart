// lib/screens/coffee_tips_screen.dart

import 'package:flutter/material.dart';

class CoffeeTipsScreen extends StatelessWidget {
  final List<Map<String, String>> brewingTips = [
    {
      'title': 'Use fresh coffee:',
      'content':
          'Brew with freshly roasted whole-bean coffee. The best timeframe to brew is 7-30 days after the roast date.',
    },
    {
      'title': 'Buy from local suppliers:',
      'content':
          'Specialty coffee from local suppliers can greatly enhance the quality of your brew.',
    },
    {
      'title': 'Understand coffee processing:',
      'content':
          'The method of processing coffee post-harvest can impact its taste. Experiment with different processes to find what suits your palate.',
    },
    {
      'title': 'Use the right grinder:',
      'content':
          'Use a coffee grinder that matches your brewing method. The quality of the grinder can significantly affect the taste of the coffee.',
    },
    {
      'title': 'Adjust grind size:',
      'content':
          'The particle size of your coffee plays a significant role in extraction and brewing time. Adjust the grind size if your espresso pours out too quickly or too slowly.',
    },
    {
      'title': 'Measure your coffee:',
      'content':
          'Use a scale for accurate measurements as coffee weight can change based on the roast type.',
    },
    {
      'title': 'Use good water:',
      'content':
          'Since water makes up 99% of your cup, its quality greatly impacts the taste of your coffee. Avoid using hard tap water, instead opt for filtered or bottled water.',
    },
    {
      'title': 'Time your brews:',
      'content':
          'Timing your coffee brews can lead to more consistent and better-tasting coffee. Adjust your grind size or brewing technique if your brew takes longer than the suggested time.',
    },
    {
      'title': 'Understand brewing temperatures:',
      'content':
          'The temperature of the water used for brewing significantly impacts the taste of the coffee. Experiment with different temperatures to find what works best for your preferred coffee roast.',
    },
    {
      'title': 'Keep your equipment clean:',
      'content':
          'Regularly clean your brewing equipment to avoid contamination from residual coffee oils. This is especially important when switching to a new coffee.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Coffee Brewing Tips'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: brewingTips.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: <TextSpan>[
                    TextSpan(
                      text: brewingTips[index]['title'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: brewingTips[index]['content']),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
