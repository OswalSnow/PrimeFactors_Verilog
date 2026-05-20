Algoritmo en pseudocodigo de la descomposición en factores primos:

    N = 12
    divisor = 2
    while (N >= 2) {

    // ===== calcular residuo =====
    cociente = N / divisor
    producto = cociente * divisor
    residuo = N - producto

    // ===== verificar si es factor =====
    if (residuo == 0) {
        print(divisor)   // factor primo encontrado
        N = cociente     // reducir N
    }
    else {
        divisor = divisor + 1
    }
}
