import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../network/recipe_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../colors.dart';
import '../recipe_card.dart';
import '../widgets/custom_dropdown.dart';
import 'recipe_details.dart';
import '../../network/recipe_service.dart';

class RecipeList extends StatefulWidget {
  const RecipeList({Key? key}) : super(key: key);

  @override
  State createState() => _RecipeListState();
}

class _RecipeListState extends State<RecipeList> {
  static const String prefSearchKey = 'previousSearches';

  late TextEditingController searchTextController;
  final ScrollController _scrollController = ScrollController();

  // TODO: Replace with new API class
  List<APIHits> currentSearchList = [];
  int currentCount = 0;
  int currentStartPosition = 0;
  int currentEndPosition = 20;
  int pageCount = 20;
  bool hasMore = false;
  bool loading = false;
  bool inErrorState = false;
  List<String> previousSearches = <String>[];
  

  @override
  void initState() {
    super.initState();
    // TODO: Remove call to loadRecipes()
    
    getPreviousSearches();
    searchTextController = TextEditingController(text: '');
    _scrollController
      .addListener(() {
        final triggerFetchMoreSize =
            0.7 * _scrollController.position.maxScrollExtent;

        if (_scrollController.position.pixels > triggerFetchMoreSize) {
          if (hasMore &&
              currentEndPosition < currentCount &&
              !loading &&
              !inErrorState) {
            setState(() {
              loading = true;
              currentStartPosition = currentEndPosition;
              currentEndPosition =
                  min(currentStartPosition + pageCount, currentCount);
            });
          }
        }
      });
  }

  // TODO: Add getRecipeData() here
  // 1
Future<APIRecipeQuery> getRecipeData(String query, int from, int
to) async {
 // 2
 final recipeJson = await RecipeService().getRecipes(query, 
from, to);
 // 3
 final recipeMap = json.decode(recipeJson);
 // 4
 return APIRecipeQuery.fromJson(recipeMap);
}

  // TODO: Delete loadRecipes()
  

  @override
  void dispose() {
    searchTextController.dispose();
    super.dispose();
  }

  void savePreviousSearches() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(prefSearchKey, previousSearches);
  }

  void getPreviousSearches() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(prefSearchKey)) {
      final searches = prefs.getStringList(prefSearchKey);
      if (searches != null) {
        previousSearches = searches;
      } else {
        previousSearches = <String>[];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            _buildSearchCard(),
            _buildRecipeLoader(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Card(
      elevation: 4,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0))),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                startSearch(searchTextController.text);
                final currentFocus = FocusScope.of(context);
                if (!currentFocus.hasPrimaryFocus) {
                  currentFocus.unfocus();
                }
              },
            ),
            const SizedBox(
              width: 6.0,
            ),
            Expanded(
              child: Row(
                children: <Widget>[
                  Expanded(
                      child: TextField(
                    decoration: const InputDecoration(
                        border: InputBorder.none, hintText: 'Search'),
                    autofocus: false,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) {
                      startSearch(searchTextController.text);
                    },
                    controller: searchTextController,
                  )),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: lightGrey,
                    ),
                    onSelected: (String value) {
                      searchTextController.text = value;
                      startSearch(searchTextController.text);
                    },
                    itemBuilder: (BuildContext context) {
                      return previousSearches
                          .map<CustomDropdownMenuItem<String>>((String value) {
                        return CustomDropdownMenuItem<String>(
                          text: value,
                          value: value,
                          callback: () {
                            setState(() {
                              previousSearches.remove(value);
                              savePreviousSearches();
                              Navigator.pop(context);
                            });
                          },
                        );
                      }).toList();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void startSearch(String value) {
    setState(() {
      currentSearchList.clear();
      currentCount = 0;
      currentEndPosition = pageCount;
      currentStartPosition = 0;
      hasMore = true;
      value = value.trim();
      if (!previousSearches.contains(value)) {
        previousSearches.add(value);
        savePreviousSearches();
      }
    });
  }

  // TODO: Replace this _buildRecipeLoader definition
  Widget _buildRecipeLoader(BuildContext context) {
 // 1
 if (searchTextController.text.length < 3) {
 return Container();
 }
 // 2
 return FutureBuilder<APIRecipeQuery>(
 // 3
 future: getRecipeData(searchTextController.text.trim(),
 currentStartPosition, currentEndPosition),
 // 4
 builder: (context, snapshot) {
 // 5
 if (snapshot.connectionState == ConnectionState.done) {
 // 6
 if (snapshot.hasError) {
 return Center(
 child: Text(snapshot.error.toString(),
 textAlign: TextAlign.center, textScaleFactor: 
1.3),
 );
 }
 // 7
 loading = false;
 final query = snapshot.data;
 inErrorState = false;
 if (query != null) {
 currentCount = query.count;
 hasMore = query.more;
 currentSearchList.addAll(query.hits);
 // 8
 if (query.to < currentEndPosition) {
 currentEndPosition = query.to;
 }
 }
 // 9
 return _buildRecipeList(context, currentSearchList);
 }
 // TODO: Handle not done connection
 // 10
else {
 // 11
 if (currentCount == 0) {
 // Show a loading indicator while waiting for the recipes
 return const Center(child: CircularProgressIndicator());
 } else {
 // 12
 return _buildRecipeList(context, currentSearchList);
 }
}
 },
 );
}

  // TODO: Add _buildRecipeList()
// 1
Widget _buildRecipeList(BuildContext recipeListContext, 
List<APIHits> hits) {
 // 2
 final size = MediaQuery.of(context).size;
 const itemHeight = 310;
 final itemWidth = size.width / 2;
 // 3
 return Flexible(
 // 4
  child: GridView.builder(
 // 5
 controller: _scrollController,
 // 6
 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
 crossAxisCount: 2,
 childAspectRatio: (itemWidth / itemHeight),
 ),
 // 7
 itemCount: hits.length,
 // 8
 itemBuilder: (BuildContext context, int index) {
 return _buildRecipeCard(recipeListContext, hits, index);
 },
 ),
 );
}
  Widget _buildRecipeCard(
      BuildContext topLevelContext, List<APIHits> hits, int index) 
      {
    final recipe = hits[index].recipe;
    return GestureDetector(
      onTap: () {
        Navigator.push(topLevelContext, MaterialPageRoute(
          builder: (context) {
            return const RecipeDetails();
          },
        ));
      },
      // TODO: Replace with recipeCard
      child: recipeCard(recipe),
    );
  }
}
