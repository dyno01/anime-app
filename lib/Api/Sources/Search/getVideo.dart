import '../Eval/dart/model/video.dart';
import '../Model/Source.dart';
import '../lib.dart';

Future<List<Video>> getVideo({
  required Source source,
  required String url,
}) async {
  List<String> domains = [];
  if (source.baseUrls != null && source.baseUrls!.isNotEmpty) {
    domains = List<String>.from(source.baseUrls!);
  } else if (source.baseUrl != null && source.baseUrl!.isNotEmpty) {
    domains = [source.baseUrl!];
  }

  Exception? lastError;
  for (var domain in domains) {
    try {
      source.baseUrl = domain;
      List<Video> list = await getExtensionService(source).getVideoList(url);
      List<Video> videos = [];
      for (var video in list) {
        if (!videos.any((element) => element.quality == video.quality)) {
          videos.add(video);
        }
      }
      if (videos.isNotEmpty) {
        return videos..sort((a, b) => a.quality.compareTo(b.quality));
      }
    } catch (e) {
      lastError = e is Exception ? e : Exception(e.toString());
      // Try next domain
    }
  }
  // If all domains fail, throw last error or return empty
  if (lastError != null) throw lastError;
  return [];
}
