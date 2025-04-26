Unit unn;

{$MODE objfpc}{$H+}

Interface

Uses
  Dialogs,
  Classes, SysUtils, unnMath;

Type

  { TNeuralNetwork }

  TSimpleNeuralNetwork = Class // Ein Klassisches 3 Schichten NN
  private
    input_nodes: integer;
    hidden_nodes: integer;
    output_nodes: integer;
    Weights_ho, Weights_ih: TMatrix; // Die Gewichte Matrix zwischen Input und Hidden
    bias_h, bias_o: TMatrix;
  public
    LearnRate: Single;
    Constructor Create(numI, numH, numO: Integer);
    Function Predict(input: TVector): TVector;
    Procedure Train(input, targets: TVector);
  End;

  TNeuralNetwork = Class
  private
    flayers: Array Of TMatrix;
    fBias: Array Of TMatrix;
    finputDim, fOutputDim: integer;
  public
    LearnRate: Single;
    Constructor Create(Layers: Array Of Integer); // z.B. [2,4,1] -> 2 Eingang, 4 hidden, 1 Output
    Function Predict(input: TVector): TVector;
    Procedure Train(input, targets: TVector);
  End;


Implementation

Function Sigmoid(x: Single): Single;
Begin
  result := 1 / (1 + exp(-x));
End;

Function DerivSigmoid(x: Single): Single;
Var
  s: Single;
Begin
  //s := Sigmoid(x); // Da der Übergabe parameter bereits via Sigmoid bearbeitet wurde, kann das hier weg gelassen werden
  s := x;
  result := s * (1 - s);
End;

{ TNeuralNetwork }

Constructor TNeuralNetwork.Create(Layers: Array Of Integer);
Var
  i: Integer;
Begin
  LearnRate := 0.1; // Egal hauptsache Definiert, macht nachher eh die Kontrollierende Anwendung
  If length(Layers) < 2 Then Begin
    Raise Exception.Create('Error, you have to select at leas 2 layers.');
  End;
  // Wir benötigen 1-Schicht weniger als Layers Angefragt sind
  setlength(fLayers, high(Layers));
  setlength(fBias, high(Layers));
  // Erstellen der ganzen Übergangsmatrizen
  For i := 0 To high(Layers) - 1 Do Begin
    flayers[i] := Matrix(Layers[i + 1], Layers[i]);
    fBias[i] := Matrix(Layers[i + 1], 1);
    Randomize(flayers[i]);
    Randomize(fBias[i]);
  End;
  // Für die Checks
  finputDim := Layers[0];
  fOutputDim := layers[high(layers)];
End;

Function TNeuralNetwork.Predict(input: TVector): TVector;
Var
  v: TMatrix;
  i: Integer;
Begin
  If length(input) <> finputDim Then Begin
    Raise exception.Create('Error, input has invalid size.');
  End;
  // Input Conversion
  v := VectorToMatrix(input);
  // FeedForward
  For i := 0 To high(flayers) Do Begin
    showmessage(Plot(flayers[i]) + LineEnding + LineEnding + Plot(v));
    v := flayers[i] * v;
    v := v + fBias[i];
    MapMatrix(v, @Sigmoid);
  End;
  // Output Conversion
  result := MatrixToVector(v);
End;

Procedure TNeuralNetwork.Train(input, targets: TVector);
Var
  v: Array Of TMatrix;
  i: Integer;
  delta, g, e: TMatrix;
Begin
  If length(input) <> finputDim Then Begin
    Raise exception.Create('Error, input has invalid size.');
  End;
  If length(targets) <> fOutputDim Then Begin
    Raise exception.Create('Error, target has invalid size.');
  End;
  // 1. Feed Forward
  setlength(v, length(flayers) + 1);
  // Input Conversion
  v[0] := VectorToMatrix(input);
  // FeedForward
  For i := 0 To high(flayers) Do Begin
    v[i + 1] := flayers[i] * v[i];
    v[i + 1] := v[i + 1] + fBias[i];
    MapMatrix(v[i + 1], @Sigmoid);
  End;
  // Output stands in v[length(flayers)]
  // 2. Back Propagation
  // Calculate Error of Output
  e := VectorToMatrix(targets) - v[length(flayers)];
  // Propagate through the layers
  For i := high(flayers) Downto 0 Do Begin
    // Calculate the Gradient
    g := MapMatrix2(v[i + 1], @DerivSigmoid);
    g := Hadamard(g, e);
    g := LearnRate * g;

    delta := g * Transpose(v[i]);

    // Adjust Weights and bias
    flayers[i] := flayers[i] + delta;
    fBias[i] := fBias[i] + g;

    // Calculate Error for next layer
    If i <> 0 Then Begin
      // i = 0 would calculate the Error from the input, this is not needed
      // anymore => not calculate it to preserve compution time
      e := Transpose(flayers[i]) * e;
    End;
  End;
End;

{ TNeuralNetwork }

Constructor TSimpleNeuralNetwork.Create(numI, numH, numO: Integer);
Begin
  LearnRate := 0.1; // Egal hauptsache Definiert, macht nachher eh die Kontrollierende Anwendung
  input_nodes := numI;
  hidden_nodes := numH;
  output_nodes := numO;
  Weights_ih := Matrix(hidden_nodes, input_nodes);
  Weights_ho := Matrix(output_nodes, hidden_nodes);
  bias_h := Matrix(hidden_nodes, 1);
  bias_o := Matrix(output_nodes, 1);
  Randomize(Weights_ih);
  Randomize(Weights_ho);
  Randomize(bias_h);
  Randomize(bias_o);
End;

Function TSimpleNeuralNetwork.predict(input: TVector): TVector;
Var
  iM, om, Hidden: TMatrix;
Begin
  // Prechecks
  If (length(input) <> input_nodes) Then Begin
    Raise exception.create('Invalid Input.')
  End;

  // Input to Matrix
  im := VectorToMatrix(input);

  // Berechnen Ausgabe Hidden Layer
  Hidden := Weights_ih * im;
  hidden := hidden + bias_h;
  MapMatrix(hidden, @Sigmoid);

  // Berechnen Ausgabe Ausgabe Layer
  om := Weights_ho * Hidden;
  om := om + bias_o;
  MapMatrix(om, @Sigmoid);

  // Matrix To Vector
  result := MatrixToVector(om);
End;

Procedure TSimpleNeuralNetwork.Train(input, targets: TVector);
Var

  gradients, hidden_gradient, Weights_ho_delta, Weights_ih_delta,

  hidden_errors,
    Output_Errors,
    Outputs: TMatrix;

  iM, // Input as Matrix
  Hidden: TMatrix; // Ausgabe des Hidden Layers

Begin
  // Schlüssel für diese Funktion ist:   https://www.youtube.com/watch?v=qB2nwJxNVxM
  // für die Bias Berechnung fehlt noch: https://www.youtube.com/watch?v=tlqinMNM4xs

  // Feed Forward
  // Prechecks // -- ff
  If (length(input) <> input_nodes) Then Begin // -- ff
    Raise exception.create('Invalid Input.') // -- ff
  End; // -- ff

  // Input to Matrix// -- ff
  im := VectorToMatrix(input); // -- ff

  // Berechnen Ausgabe Hidden Layer// -- ff
  Hidden := Weights_ih * im; // -- ff
  hidden := hidden + bias_h; // -- ff
  MapMatrix(hidden, @Sigmoid); // -- ff

  // Berechnen Ausgabe Ausgabe Layer// -- ff
  Outputs := Weights_ho * Hidden; // -- ff
  Outputs := Outputs + bias_o; // -- ff
  MapMatrix(Outputs, @Sigmoid); // -- ff

  // Error BackPropagation
  // Calculate the Error
  Output_Errors := VectorToMatrix(targets) - Outputs;

  // Calculate Gradient for hiddon -> Output
  gradients := MapMatrix2(Outputs, @DerivSigmoid);
  gradients := Hadamard(gradients, Output_Errors);
  gradients := LearnRate * gradients;


  // Adjust the weights by deltas
  Weights_ho_delta := gradients * Transpose(hidden);
  // Adjust the bias by its deltas (which is just the gradients)
  bias_o := bias_o + gradients;

  // Adjusting the Weights
  Weights_ho := Weights_ho + Weights_ho_delta;

  // Calculate the Error of the Hidden Layer
  hidden_errors := Transpose(Weights_ho) * Output_Errors;

  // Calculate Gradient for input -> hidden
  hidden_gradient := MapMatrix2(Hidden, @DerivSigmoid);
  hidden_gradient := Hadamard(hidden_gradient, hidden_errors);
  hidden_gradient := LearnRate * hidden_gradient;

  Weights_ih_delta := hidden_gradient * Transpose(im);


  // Adjust the weights by deltas
  Weights_ih := Weights_ih + Weights_ih_delta;
  // Adjust the bias by its deltas (which is just the gradients)
  bias_h := bias_h + hidden_gradient;
End;

End.

