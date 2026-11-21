/// Predefined IPTV playlist catalog sourced from iptv-org GitHub Pages.
///
/// All URLs point to the iptv-org/iptv GitHub Pages CDN — a stable, publicly
/// available, community-maintained dataset of free-to-air and legal streams.
/// No pirated, paywalled, or geo-restricted content is included.
library;

import 'iptv_models.dart';

class IptvCatalog {
  const IptvCatalog._();

  static const _base = 'https://iptv-org.github.io/iptv';

  /// All channels in a single playlist (large, ~100MB).
  static const allChannels = IptvSource(
    id: 'all',
    name: 'All Channels',
    url: '$_base/index.m3u',
    description: 'Every channel in the iptv-org database',
  );

  /// Playlists grouped by category.
  static const byCategory = [
    IptvSource(id: 'cat_animation', name: 'Animation', url: '$_base/categories/animation.m3u', description: 'Animated content', type: IptvSourceType.category),
    IptvSource(id: 'cat_auto', name: 'Auto', url: '$_base/categories/auto.m3u', description: 'Automotive channels', type: IptvSourceType.category),
    IptvSource(id: 'cat_business', name: 'Business', url: '$_base/categories/business.m3u', description: 'Business & finance', type: IptvSourceType.category),
    IptvSource(id: 'cat_classic', name: 'Classic', url: '$_base/categories/classic.m3u', description: 'Classic TV & movies', type: IptvSourceType.category),
    IptvSource(id: 'cat_comedy', name: 'Comedy', url: '$_base/categories/comedy.m3u', description: 'Comedy channels', type: IptvSourceType.category),
    IptvSource(id: 'cat_cooking', name: 'Cooking', url: '$_base/categories/cooking.m3u', description: 'Cooking & food', type: IptvSourceType.category),
    IptvSource(id: 'cat_culture', name: 'Culture', url: '$_base/categories/culture.m3u', description: 'Culture & arts', type: IptvSourceType.category),
    IptvSource(id: 'cat_documentary', name: 'Documentary', url: '$_base/categories/documentary.m3u', description: 'Documentaries', type: IptvSourceType.category),
    IptvSource(id: 'cat_education', name: 'Education', url: '$_base/categories/education.m3u', description: 'Educational content', type: IptvSourceType.category),
    IptvSource(id: 'cat_entertainment', name: 'Entertainment', url: '$_base/categories/entertainment.m3u', description: 'General entertainment', type: IptvSourceType.category),
    IptvSource(id: 'cat_family', name: 'Family', url: '$_base/categories/family.m3u', description: 'Family-friendly', type: IptvSourceType.category),
    IptvSource(id: 'cat_general', name: 'General', url: '$_base/categories/general.m3u', description: 'General interest', type: IptvSourceType.category),
    IptvSource(id: 'cat_kids', name: 'Kids', url: '$_base/categories/kids.m3u', description: 'Children\'s channels', type: IptvSourceType.category),
    IptvSource(id: 'cat_legislative', name: 'Legislative', url: '$_base/categories/legislative.m3u', description: 'Government & legislative', type: IptvSourceType.category),
    IptvSource(id: 'cat_lifestyle', name: 'Lifestyle', url: '$_base/categories/lifestyle.m3u', description: 'Lifestyle & living', type: IptvSourceType.category),
    IptvSource(id: 'cat_movies', name: 'Movies', url: '$_base/categories/movies.m3u', description: 'Movie channels', type: IptvSourceType.category),
    IptvSource(id: 'cat_music', name: 'Music', url: '$_base/categories/music.m3u', description: 'Music channels', type: IptvSourceType.category),
    IptvSource(id: 'cat_news', name: 'News', url: '$_base/categories/news.m3u', description: 'News channels', type: IptvSourceType.category),
    IptvSource(id: 'cat_outdoor', name: 'Outdoor', url: '$_base/categories/outdoor.m3u', description: 'Outdoor & nature', type: IptvSourceType.category),
    IptvSource(id: 'cat_relax', name: 'Relax', url: '$_base/categories/relax.m3u', description: 'Relaxation & ambient', type: IptvSourceType.category),
    IptvSource(id: 'cat_religious', name: 'Religious', url: '$_base/categories/religious.m3u', description: 'Religious channels', type: IptvSourceType.category),
    IptvSource(id: 'cat_science', name: 'Science', url: '$_base/categories/science.m3u', description: 'Science & technology', type: IptvSourceType.category),
    IptvSource(id: 'cat_series', name: 'Series', url: '$_base/categories/series.m3u', description: 'TV series', type: IptvSourceType.category),
    IptvSource(id: 'cat_shop', name: 'Shop', url: '$_base/categories/shop.m3u', description: 'Shopping channels', type: IptvSourceType.category),
    IptvSource(id: 'cat_sports', name: 'Sports', url: '$_base/categories/sports.m3u', description: 'Sports channels', type: IptvSourceType.category),
    IptvSource(id: 'cat_travel', name: 'Travel', url: '$_base/categories/travel.m3u', description: 'Travel & tourism', type: IptvSourceType.category),
    IptvSource(id: 'cat_weather', name: 'Weather', url: '$_base/categories/weather.m3u', description: 'Weather channels', type: IptvSourceType.category),
  ];

  /// Popular country playlists.
  static const byCountry = [
    IptvSource(id: 'country_in', name: 'India', url: '$_base/countries/in.m3u', description: 'Indian channels', type: IptvSourceType.country),
    IptvSource(id: 'country_us', name: 'United States', url: '$_base/countries/us.m3u', description: 'US channels', type: IptvSourceType.country),
    IptvSource(id: 'country_gb', name: 'United Kingdom', url: '$_base/countries/gb.m3u', description: 'UK channels', type: IptvSourceType.country),
    IptvSource(id: 'country_ca', name: 'Canada', url: '$_base/countries/ca.m3u', description: 'Canadian channels', type: IptvSourceType.country),
    IptvSource(id: 'country_au', name: 'Australia', url: '$_base/countries/au.m3u', description: 'Australian channels', type: IptvSourceType.country),
    IptvSource(id: 'country_de', name: 'Germany', url: '$_base/countries/de.m3u', description: 'German channels', type: IptvSourceType.country),
    IptvSource(id: 'country_fr', name: 'France', url: '$_base/countries/fr.m3u', description: 'French channels', type: IptvSourceType.country),
    IptvSource(id: 'country_br', name: 'Brazil', url: '$_base/countries/br.m3u', description: 'Brazilian channels', type: IptvSourceType.country),
    IptvSource(id: 'country_jp', name: 'Japan', url: '$_base/countries/jp.m3u', description: 'Japanese channels', type: IptvSourceType.country),
    IptvSource(id: 'country_kr', name: 'South Korea', url: '$_base/countries/kr.m3u', description: 'Korean channels', type: IptvSourceType.country),
    IptvSource(id: 'country_mx', name: 'Mexico', url: '$_base/countries/mx.m3u', description: 'Mexican channels', type: IptvSourceType.country),
    IptvSource(id: 'country_es', name: 'Spain', url: '$_base/countries/es.m3u', description: 'Spanish channels', type: IptvSourceType.country),
    IptvSource(id: 'country_it', name: 'Italy', url: '$_base/countries/it.m3u', description: 'Italian channels', type: IptvSourceType.country),
    IptvSource(id: 'country_ru', name: 'Russia', url: '$_base/countries/ru.m3u', description: 'Russian channels', type: IptvSourceType.country),
    IptvSource(id: 'country_cn', name: 'China', url: '$_base/countries/cn.m3u', description: 'Chinese channels', type: IptvSourceType.country),
    IptvSource(id: 'country_ae', name: 'UAE', url: '$_base/countries/ae.m3u', description: 'UAE channels', type: IptvSourceType.country),
    IptvSource(id: 'country_sa', name: 'Saudi Arabia', url: '$_base/countries/sa.m3u', description: 'Saudi channels', type: IptvSourceType.country),
    IptvSource(id: 'country_tr', name: 'Turkey', url: '$_base/countries/tr.m3u', description: 'Turkish channels', type: IptvSourceType.country),
    IptvSource(id: 'country_id', name: 'Indonesia', url: '$_base/countries/id.m3u', description: 'Indonesian channels', type: IptvSourceType.country),
    IptvSource(id: 'country_ng', name: 'Nigeria', url: '$_base/countries/ng.m3u', description: 'Nigerian channels', type: IptvSourceType.country),
  ];

  /// Popular language playlists.
  static const byLanguage = [
    IptvSource(id: 'lang_hin', name: 'Hindi', url: '$_base/languages/hin.m3u', description: 'Hindi channels', type: IptvSourceType.language),
    IptvSource(id: 'lang_eng', name: 'English', url: '$_base/languages/eng.m3u', description: 'English channels', type: IptvSourceType.language),
    IptvSource(id: 'lang_spa', name: 'Spanish', url: '$_base/languages/spa.m3u', description: 'Spanish channels', type: IptvSourceType.language),
    IptvSource(id: 'lang_por', name: 'Portuguese', url: '$_base/languages/por.m3u', description: 'Portuguese channels', type: IptvSourceType.language),
    IptvSource(id: 'lang_ara', name: 'Arabic', url: '$_base/languages/ara.m3u', description: 'Arabic channels', type: IptvSourceType.language),
    IptvSource(id: 'lang_fra', name: 'French', url: '$_base/languages/fra.m3u', description: 'French channels', type: IptvSourceType.language),
    IptvSource(id: 'lang_deu', name: 'German', url: '$_base/languages/deu.m3u', description: 'German channels', type: IptvSourceType.language),
    IptvSource(id: 'lang_jpn', name: 'Japanese', url: '$_base/languages/jpn.m3u', description: 'Japanese channels', type: IptvSourceType.language),
    IptvSource(id: 'lang_kor', name: 'Korean', url: '$_base/languages/kor.m3u', description: 'Korean channels', type: IptvSourceType.language),
    IptvSource(id: 'lang_zho', name: 'Chinese', url: '$_base/languages/zho.m3u', description: 'Chinese channels', type: IptvSourceType.language),
    IptvSource(id: 'lang_rus', name: 'Russian', url: '$_base/languages/rus.m3u', description: 'Russian channels', type: IptvSourceType.language),
    IptvSource(id: 'lang_ita', name: 'Italian', url: '$_base/languages/ita.m3u', description: 'Italian channels', type: IptvSourceType.language),
    IptvSource(id: 'lang_tur', name: 'Turkish', url: '$_base/languages/tur.m3u', description: 'Turkish channels', type: IptvSourceType.language),
    IptvSource(id: 'lang_tam', name: 'Tamil', url: '$_base/languages/tam.m3u', description: 'Tamil channels', type: IptvSourceType.language),
    IptvSource(id: 'lang_tel', name: 'Telugu', url: '$_base/languages/tel.m3u', description: 'Telugu channels', type: IptvSourceType.language),
    IptvSource(id: 'lang_ben', name: 'Bengali', url: '$_base/languages/ben.m3u', description: 'Bengali channels', type: IptvSourceType.language),
    IptvSource(id: 'lang_mal', name: 'Malayalam', url: '$_base/languages/mal.m3u', description: 'Malayalam channels', type: IptvSourceType.language),
    IptvSource(id: 'lang_kan', name: 'Kannada', url: '$_base/languages/kan.m3u', description: 'Kannada channels', type: IptvSourceType.language),
    IptvSource(id: 'lang_mar', name: 'Marathi', url: '$_base/languages/mar.m3u', description: 'Marathi channels', type: IptvSourceType.language),
    IptvSource(id: 'lang_guj', name: 'Gujarati', url: '$_base/languages/guj.m3u', description: 'Gujarati channels', type: IptvSourceType.language),
  ];

  /// Every source in the catalog, flattened.
  static List<IptvSource> get all => [
        allChannels,
        ...byCategory,
        ...byCountry,
        ...byLanguage,
      ];

  /// Look up a source by its id.
  static IptvSource? findById(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Search sources by name (case-insensitive substring).
  static List<IptvSource> search(String query) {
    if (query.isEmpty) return all;
    final q = query.toLowerCase();
    return all.where((s) => s.name.toLowerCase().contains(q)).toList();
  }
}
