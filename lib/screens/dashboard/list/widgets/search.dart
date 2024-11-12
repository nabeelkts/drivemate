import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

class SearchBarWidgets extends StatelessWidget {
  const SearchBarWidgets({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 35,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.orange,
          width: 1.4,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  IconlyLight.search,
                  color: Colors.grey,
                ),
              ),
              Text(
                '',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(25),
            ),
            height: 35,
            width: 75,
            child: const Center(
              child: Text(
                'Search',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
