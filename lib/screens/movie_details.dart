import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_netflix/cubit/movie_details_tab_cubit.dart';
import 'package:flutter_netflix/widgets/episode_box.dart';
import 'package:flutter_netflix/widgets/netflix_dropdown.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:video_player/video_player.dart';

import '../bloc/netflix_bloc.dart';
import '../model/movie.dart';
import '../repository/repository.dart';
import '../utils/utils.dart';
import '../widgets/movie_box.dart';
import '../widgets/movie_trailer.dart';
import '../widgets/new_and_hot_tile_action.dart';

class MovieDetailsScreen extends StatefulWidget {
  const MovieDetailsScreen({super.key, required this.movie});

  final Movie movie;

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: widget.movie.type == 'tv' ? 3 : 2, vsync: this)
        ..addListener(() {
          context.read<MovieDetailsTabCubit>().setTab(_tabController.index);
        });

  @override
  void initState() {
    if (widget.movie.type == 'tv') {
      context
          .read<TvShowSeasonSelectorBloc>()
          .add(SelectTvShowSeason(widget.movie.id, 1));
    }
    context.read<MovieDetailsTabCubit>().setTab(_tabController.index);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final configuration = context.watch<ConfigurationBloc>().state;

    if (widget.movie.details) {
      return _buildDetails(widget.movie, configuration);
    }
    return FutureBuilder(
        future: context
            .watch<TMDBRepository>()
            .getDetails(widget.movie.id, widget.movie.type),
        builder: (context, AsyncSnapshot<Movie> snapshoot) {
          if (snapshoot.hasError || !snapshoot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildDetails(snapshoot.data!, configuration);
        });
  }

  Widget _buildDetails(Movie movie, ConfigurationState configuration) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.cast),
              onPressed: () {},
            ),
          ],
          pinned: true,
        ),
        SliverList(
            delegate: SliverChildListDelegate.fixed([
          const BumbleBeeRemoteVideo(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              movie.name,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold, fontSize: 32.0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text(
                  '${movie.releaseDate!.year}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(
                  width: 8.0,
                ),
                Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6.0, vertical: 2.0),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4.0),
                        color: Colors.grey.shade700),
                    child: const Text(
                      '16+',
                      style: TextStyle(letterSpacing: 1.0),
                    )),
                const SizedBox(
                  width: 8.0,
                ),
                Text(
                  movie.getRuntime(),
                  style: TextStyle(color: Colors.grey.shade400),
                ),
                const SizedBox(
                  width: 8.0,
                ),
                Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6.0, vertical: 2.0),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2.0),
                        color: Colors.grey.shade300),
                    child: const Text(
                      'HD',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w400),
                    ))
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16.0),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black),
                onPressed: () {},
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play')),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16.0),
                    backgroundColor: Colors.grey.shade900,
                    foregroundColor: Colors.white),
                onPressed: () {},
                icon: const Icon(LucideIcons.download),
                label: const Text('Download S1:E1')),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(movie.overview),
                const SizedBox(
                  height: 8.0,
                ),
                const Text(
                    'Starring: Bob Odenkirk, Jonathan Banks, Rhea Seehorn...'),
                const SizedBox(
                  height: 8.0,
                ),
                const Text('Creators: Vince Gilligan, Peter Gould'),
              ],
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              NewAndHotTileAction(
                icon: LucideIcons.plus,
                label: 'My List',
              ),
              NewAndHotTileAction(
                icon: LucideIcons.thumbsUp,
                label: 'Rate',
              ),
              NewAndHotTileAction(
                icon: LucideIcons.share2,
                label: 'Share',
              ),
              NewAndHotTileAction(
                icon: LucideIcons.download,
                label: 'Download Season 1',
              )
            ],
          ),
          const Divider(
            height: 1.0,
          ),
          TabBar(
              controller: _tabController,
              indicator: const BoxDecoration(
                border: Border(
                    top: BorderSide(
                  color: redColor,
                  width: 4.0,
                )),
              ),
              tabs: [
                if (movie.type == 'tv')
                  const Tab(
                    text: 'Episodes',
                  ),
                const Tab(
                  text: 'Trailers & More',
                ),
                const Tab(
                  text: 'More Like This',
                ),
              ]),
        ])),
        Builder(builder: (context) {
          final tabIndex = context.watch<MovieDetailsTabCubit>().state;
          if (tabIndex == 0 && movie.type == 'tv') {
            final state = context.watch<TvShowSeasonSelectorBloc>().state;
            if (state is SelectedTvShowSeason) {
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index == 0) {
                    return _seasonDropdown(movie, state.season.seasonNumber);
                  }

                  return EpisodeBox(
                      episode: state.season.episodes[index - 1],
                      fill: true,
                      padding: EdgeInsets.zero);
                }, childCount: state.season.episodes.length + 1),
              );
            }
          } else if (tabIndex == 1 && movie.type == 'tv' ||
              tabIndex == 0 && movie.type == 'movie') {
            final movies = context.watch<TrendingMovieListDailyBloc>().state;

            if (movies is TrendingMovieListDaily) {
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final movie = movies.list[index];
                  return MovieTrailer(
                      key: ValueKey(movie.id),
                      movie: movie,
                      fill: true,
                      padding: EdgeInsets.zero);
                }, childCount: movies.list.length),
              );
            }
          } else {
            final movies = context.watch<TrendingTvShowListDailyBloc>().state;
            if (movies is TrendingTvShowListDaily) {
              return SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final movie = movies.list[index];
                  return MovieBox(
                      key: ValueKey(movie.id),
                      movie: movie,
                      fill: true,
                      padding: EdgeInsets.zero);
                }, childCount: min(12, movies.list.length)),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2 / 3,
                    mainAxisSpacing: 8.0,
                    crossAxisSpacing: 8.0),
              );
            }
          }
          return const SliverToBoxAdapter();
        })
      ],
    );
  }

  void _openSeasonSelector(Movie movie) {
    OverlayEntry? overlay;
    overlay = OverlayEntry(
      builder: (context) {
        return NetflixDropDownScreen(
            movie: movie,
            selected: (context.read<TvShowSeasonSelectorBloc>().state
                    as SelectedTvShowSeason)
                .season
                .seasonNumber,
            onPop: () {
              overlay?.remove();
            });
      },
    );

    Overlay.of(context, rootOverlay: true).insert(overlay);
  }

  Widget _seasonDropdown(Movie movie, int seasonNumber) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade900),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Season $seasonNumber',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  width: 8.0,
                ),
                const Icon(
                  LucideIcons.chevronDown,
                  size: 14.0,
                )
              ],
            ),
            onPressed: () {
              _openSeasonSelector(movie);
            }),
        const SizedBox(
          height: 8.0,
        )
      ],
    );
  }
}

class BumbleBeeRemoteVideo extends StatefulWidget {
  const BumbleBeeRemoteVideo({super.key});

  @override
  BumbleBeeRemoteVideoState createState() => BumbleBeeRemoteVideoState();
}

class BumbleBeeRemoteVideoState extends State<BumbleBeeRemoteVideo> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    _controller.addListener(() {
      setState(() {});
    });
    _controller.setLooping(true);

    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  VideoPlayer(_controller),
                  ClosedCaption(text: _controller.value.caption.text),
                  _ControlsOverlay(controller: _controller),
                  VideoProgressIndicator(_controller, allowScrubbing: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({required this.controller});

  static const List<Duration> _exampleCaptionOffsets = <Duration>[
    Duration(seconds: -10),
    Duration(seconds: -3),
    Duration(seconds: -1, milliseconds: -500),
    Duration(milliseconds: -250),
    Duration.zero,
    Duration(milliseconds: 250),
    Duration(seconds: 1, milliseconds: 500),
    Duration(seconds: 3),
    Duration(seconds: 10),
  ];
  static const List<double> _examplePlaybackRates = <double>[
    0.25,
    0.5,
    1.0,
    1.5,
    2.0,
    3.0,
    5.0,
    10.0,
  ];

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: controller.value.isPlaying
              ? const SizedBox.shrink()
              : Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 100.0,
                      semanticLabel: 'Play',
                    ),
                  ),
                ),
        ),
        GestureDetector(
          onTap: () {
            controller.value.isPlaying ? controller.pause() : controller.play();
          },
        ),
        Align(
          alignment: Alignment.topLeft,
          child: PopupMenuButton<Duration>(
            initialValue: controller.value.captionOffset,
            tooltip: 'Caption Offset',
            onSelected: (Duration delay) {
              controller.setCaptionOffset(delay);
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<Duration>>[
                for (final Duration offsetDuration in _exampleCaptionOffsets)
                  PopupMenuItem<Duration>(
                    value: offsetDuration,
                    child: Text('${offsetDuration.inMilliseconds}ms'),
                  )
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                // Using less vertical padding as the text is also longer
                // horizontally, so it feels like it would need more spacing
                // horizontally (matching the aspect ratio of the video).
                vertical: 12,
                horizontal: 16,
              ),
              child: Text('${controller.value.captionOffset.inMilliseconds}ms'),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: PopupMenuButton<double>(
            initialValue: controller.value.playbackSpeed,
            tooltip: 'Playback speed',
            onSelected: (double speed) {
              controller.setPlaybackSpeed(speed);
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<double>>[
                for (final double speed in _examplePlaybackRates)
                  PopupMenuItem<double>(
                    value: speed,
                    child: Text('${speed}x'),
                  )
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                // Using less vertical padding as the text is also longer
                // horizontally, so it feels like it would need more spacing
                // horizontally (matching the aspect ratio of the video).
                vertical: 12,
                horizontal: 16,
              ),
              child: Text('${controller.value.playbackSpeed}x'),
            ),
          ),
        ),
      ],
    );
  }
}
