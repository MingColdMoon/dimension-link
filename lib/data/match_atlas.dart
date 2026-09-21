import 'dart:math' as math;

import '../models/models.dart';

/// 一位住民的地理与爱好画像，供客户端推荐引擎使用。
class MatchPortrait {
  const MatchPortrait({
    required this.userId,
    required this.city,
    required this.district,
    required this.latitude,
    required this.longitude,
    required this.hobbies,
    this.online = false,
  });

  final String userId;
  final String city;
  final String district;
  final double latitude;
  final double longitude;
  final List<String> hobbies;
  final bool online;
}

/// 次元坐标与爱好图鉴。已知住民用精确画像，陌生住民按 id 稳定散列。
class MatchAtlas {
  MatchAtlas._();

  static const portraits = <String, MatchPortrait>{
    'u_me': MatchPortrait(
      userId: 'u_me',
      city: '上海',
      district: '徐汇',
      latitude: 31.1886,
      longitude: 121.4370,
      hobbies: ['插画', '同人', '配色', '短篇'],
      online: true,
    ),
    'u_tsukimi': MatchPortrait(
      userId: 'u_tsukimi',
      city: '上海',
      district: '静安',
      latitude: 31.2272,
      longitude: 121.4530,
      hobbies: ['同人', '乙女', '连载', '黑猫'],
      online: true,
    ),
    'u_sakurai': MatchPortrait(
      userId: 'u_sakurai',
      city: '上海',
      district: '黄浦',
      latitude: 31.2317,
      longitude: 121.4840,
      hobbies: ['COS', '漫展', '妆造', '约拍'],
      online: true,
    ),
    'u_nanami': MatchPortrait(
      userId: 'u_nanami',
      city: '杭州',
      district: '西湖',
      latitude: 30.2590,
      longitude: 120.1300,
      hobbies: ['声优', '电台', '广播剧', '角色歌'],
    ),
    'u_kaede': MatchPortrait(
      userId: 'u_kaede',
      city: '上海',
      district: '浦东',
      latitude: 31.2211,
      longitude: 121.5440,
      hobbies: ['游戏', '开黑', '夜猫', '语音'],
      online: true,
    ),
    'u_tanuki': MatchPortrait(
      userId: 'u_tanuki',
      city: '北京',
      district: '朝阳',
      latitude: 39.9210,
      longitude: 116.4430,
      hobbies: ['番剧', '安利', '催泪', '新番'],
    ),
    'u_yukimi': MatchPortrait(
      userId: 'u_yukimi',
      city: '上海',
      district: '徐汇',
      latitude: 31.1910,
      longitude: 121.4410,
      hobbies: ['插画', '水彩', '同人', '配色'],
      online: true,
    ),
    'u_yoru': MatchPortrait(
      userId: 'u_yoru',
      city: '上海',
      district: '长宁',
      latitude: 31.2204,
      longitude: 121.4240,
      hobbies: ['COS', '夜拍', '漫展', '妆造'],
      online: true,
    ),
    'u_momo': MatchPortrait(
      userId: 'u_momo',
      city: '杭州',
      district: '滨江',
      latitude: 30.2080,
      longitude: 120.2120,
      hobbies: ['绘圈', '甜品', '配色', '插画'],
    ),
    'u_ritsu': MatchPortrait(
      userId: 'u_ritsu',
      city: '广州',
      district: '天河',
      latitude: 23.1350,
      longitude: 113.3260,
      hobbies: ['声优', '广播剧', '角色歌', '同人'],
    ),
    'u_aoi': MatchPortrait(
      userId: 'u_aoi',
      city: '成都',
      district: '武侯',
      latitude: 30.6420,
      longitude: 104.0430,
      hobbies: ['游戏', '开黑', '音游', '语音'],
    ),
    'u_haku': MatchPortrait(
      userId: 'u_haku',
      city: '上海',
      district: '闵行',
      latitude: 31.1128,
      longitude: 121.3810,
      hobbies: ['番剧', '同人', '乙女', '短篇'],
      online: true,
    ),
  };

  static const _fallbackCities = <MatchPortrait>[
    MatchPortrait(
      userId: 'fb0',
      city: '上海',
      district: '徐汇',
      latitude: 31.1886,
      longitude: 121.4370,
      hobbies: [],
    ),
    MatchPortrait(
      userId: 'fb1',
      city: '上海',
      district: '浦东',
      latitude: 31.2211,
      longitude: 121.5440,
      hobbies: [],
    ),
    MatchPortrait(
      userId: 'fb2',
      city: '杭州',
      district: '西湖',
      latitude: 30.2590,
      longitude: 120.1300,
      hobbies: [],
    ),
    MatchPortrait(
      userId: 'fb3',
      city: '北京',
      district: '朝阳',
      latitude: 39.9210,
      longitude: 116.4430,
      hobbies: [],
    ),
    MatchPortrait(
      userId: 'fb4',
      city: '广州',
      district: '天河',
      latitude: 23.1350,
      longitude: 113.3260,
      hobbies: [],
    ),
    MatchPortrait(
      userId: 'fb5',
      city: '成都',
      district: '武侯',
      latitude: 30.6420,
      longitude: 104.0430,
      hobbies: [],
    ),
  ];

  /// 从简介 / 徽章 / 圈子里识别爱好关键词。
  static const hobbyLexicon = <String, List<String>>{
    '插画': ['插画', '绘圈', '速写', '厚涂', '配色', '水彩', '画'],
    '同人': ['同人', '短篇', '连载', '乙女', '群像', 'CP'],
    'COS': ['COS', 'COSER', '漫展', '妆造', '假发', '约拍', '夜拍'],
    '番剧': ['番剧', '安利', '新番', '催泪', '片子'],
    '游戏': ['游戏', '开黑', '排位', '主播', '音游', '辅助'],
    '声优': ['声优', '电台', '耳机', '广播剧', '角色歌', '切片'],
  };

  static MatchPortrait portraitOf(AppUser user) {
    final known = portraits[user.id];
    if (known != null) {
      return known;
    }
    final spot = _fallbackCities[user.id.hashCode.abs() % _fallbackCities.length];
    return MatchPortrait(
      userId: user.id,
      city: user.city.isNotEmpty ? user.city : spot.city,
      district: user.district.isNotEmpty ? user.district : spot.district,
      latitude: spot.latitude,
      longitude: spot.longitude,
      hobbies: inferHobbies(user),
      online: user.id.hashCode.abs() % 3 == 0,
    );
  }

  static List<String> inferHobbies(AppUser user, {List<String> extra = const []}) {
    final known = portraits[user.id];
    final collected = <String>{
      if (known != null) ...known.hobbies,
      ...user.hobbies,
      ...extra,
    };
    final corpus = [user.bio, user.signature, ...user.badges, ...extra].join(' ');
    hobbyLexicon.forEach((hobby, keys) {
      if (keys.any(corpus.contains)) {
        collected.add(hobby);
      }
    });
    return collected.toList();
  }

  static double distanceKm(MatchPortrait a, MatchPortrait b) {
    const earth = 6371.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final hav = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(a.latitude)) * math.cos(_rad(b.latitude)) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return 2 * earth * math.asin(math.sqrt(hav.clamp(0.0, 1.0)));
  }

  static double _rad(double deg) => deg * math.pi / 180;
}
