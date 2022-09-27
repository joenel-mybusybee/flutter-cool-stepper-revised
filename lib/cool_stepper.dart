library cool_stepper;

export 'package:cool_stepper/src/models/cool_step.dart';
export 'package:cool_stepper/src/models/cool_stepper_config.dart';

import 'package:another_flushbar/flushbar.dart';

import 'package:cool_stepper/src/models/cool_step.dart';
import 'package:cool_stepper/src/models/cool_stepper_config.dart';
import 'package:cool_stepper/src/widgets/cool_stepper_view.dart';
import 'package:flutter/material.dart';

/// CoolStepper
class CoolStepper extends StatefulWidget {
  /// The steps of the stepper whose titles, subtitles, content always get shown.
  ///
  /// The length of [steps] must not change.
  final List<CoolStep> steps;

  /// Actions to take when the final stepper is passed
  final VoidCallback onCompleted;

  /// Padding for the content inside the stepper
  final EdgeInsetsGeometry contentPadding;

  /// CoolStepper config
  final CoolStepperConfig config;

  /// This determines if or not a snackbar displays your error message if validation fails
  ///
  /// default is false
  final bool showErrorSnackbar;

  // perform action on counter clicked
  final bool canJumpToStep;

  const CoolStepper({
    Key? key,
    required this.steps,
    required this.onCompleted,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 20.0),
    this.config = const CoolStepperConfig(),
    this.showErrorSnackbar = false,
    required this.canJumpToStep
  }) : super(key: key);

  @override
  _CoolStepperState createState() => _CoolStepperState();
}

class _CoolStepperState extends State<CoolStepper> {
  PageController? _controller = PageController();

  int currentStep = 0;

  @override
  void dispose() {
    _controller!.dispose();
    _controller = null;
    super.dispose();
  }

  Future<void>? switchToPage(int page) {
    _controller!.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  bool _isFirst(int index) {
    return index == 0;
  }

  bool _isLast(int index) {
    return widget.steps.length - 1 == index;
  }

  void onStepNext() {
    final validation = widget.steps[currentStep].validation!();

    /// [validation] is null, no validation rule
    if (validation == null) {
      if (!_isLast(currentStep)) {
        setState(() {
          currentStep++;
        });
        FocusScope.of(context).unfocus();
        switchToPage(currentStep);
      } else {
        widget.onCompleted();
      }
    } else {
      /// [showErrorSnackbar] is true, Show error snackbar rule
      if (widget.showErrorSnackbar) {
        final flush = Flushbar(
          message: validation,
          flushbarStyle: FlushbarStyle.FLOATING,
          margin: EdgeInsets.all(8.0),
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
          icon: Icon(
            Icons.info_outline,
            size: 28.0,
            color: Theme.of(context).primaryColor,
          ),
          duration: Duration(seconds: 2),
          leftBarIndicatorColor: Theme.of(context).primaryColor,
        );
        flush.show(context);

        // final snackBar = SnackBar(content: Text(validation));
        // ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  void onStepBack() {
    if (!_isFirst(currentStep)) {
      setState(() {
        currentStep--;
      });
      switchToPage(currentStep);
    }
  }

  Widget jumpToStepsListContainer(BuildContext dialogContext) {
    return Container(
      height: MediaQuery.of(context).size.height - 200,
      width: MediaQuery.of(context).size.width - 50,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: widget.steps.length,
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                currentStep = index;
              });
              switchToPage(currentStep);
              Navigator.pop(dialogContext);
            },
            child: ListTile(
              leading: CircleAvatar(child: Text("${index+1}")),
              title: Text(widget.steps[index].title),
              // subtitle: Text(widget.steps[index].subtitle),
            )
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Expanded(
      child: PageView(
        controller: _controller,
        physics: NeverScrollableScrollPhysics(),
        children: widget.steps.map((step) {
          return CoolStepperView(
            step: step,
            contentPadding: widget.contentPadding,
            config: widget.config,
          );
        }).toList(),
      ),
    );

    final counter = TextButton(
      onPressed: () {
        if(widget.canJumpToStep) {
          showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: Text('Jump to step'),
                content: jumpToStepsListContainer(dialogContext),
              );
            }
          );
        }
      },
      child: Text(
        "${widget.config.stepText ?? 'STEP'} ${currentStep + 1} ${widget.config.ofText ?? 'OF'} ${widget.steps.length}",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue
        ),
      ),
    );

    String getNextLabel() {
      String nextLabel;
      if (_isLast(currentStep)) {
        nextLabel = widget.config.finalText ?? 'FINISH';
      } else {
        if (widget.config.nextTextList != null) {
          nextLabel = widget.config.nextTextList![currentStep];
        } else {
          nextLabel = widget.config.nextText ?? 'NEXT';
        }
      }
      return nextLabel;
    }

    String getPrevLabel() {
      String backLabel;
      if (_isFirst(currentStep)) {
        backLabel = '';
      } else {
        if (widget.config.backTextList != null) {
          backLabel = widget.config.backTextList![currentStep - 1];
        } else {
          backLabel = widget.config.backText ?? 'PREV';
        }
      }
      return backLabel;
    }

    final buttons = Container(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          TextButton(
            onPressed: onStepBack,
            child: Text(
              getPrevLabel(),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          counter,
          TextButton(
            onPressed: onStepNext,
            child: Text(
              getNextLabel(),
              style: TextStyle(
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      child: Column(
        children: [content, buttons],
      ),
    );
  }
}
