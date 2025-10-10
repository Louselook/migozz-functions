// enum RegStep { empty, language, fullName, location, socialEcosystem }

// class BotResponse {
//   final String text;
//   final List<String> options;
//   final RegStep step;
//   final bool valid;
//   final bool keepTalk;
//   final int? action;
//   final String? extracted;

//   const BotResponse({
//     required this.text,
//     this.options = const [],
//     this.step = RegStep.empty,
//     this.valid = false,
//     this.keepTalk = false,
//     this.action,
//     this.extracted,
//   });

//   factory BotResponse.fromJson(Map<String, dynamic> j) {
//     return BotResponse(
//       text: j['text']?.toString() ?? '',
//       options: (j['options'] as List?)?.map((e) => e.toString()).toList() ?? [],
//       step: (j['step']),
//       valid: j['valid'] == true,
//       keepTalk: j['keepTalk'] == true,
//       action: j['action'] is int
//           ? j['action'] as int
//           : int.tryParse('${j['action']}'),
//       extracted: j['extracted']?.toString(),
//     );
//   }

//   Map<String, dynamic> toJson() => {
//     'text': text,
//     'options': options,
//     'step': step.toString().split('.').last,
//     'valid': valid,
//     'keepTalk': keepTalk,
//     'action': action,
//     'extracted': extracted,
//   };
// }
