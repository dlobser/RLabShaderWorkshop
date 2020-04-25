using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Quad : MonoBehaviour {

	void Start () {
        
        Mesh mesh = new Mesh();
        GetComponent<MeshFilter>().mesh = mesh;

        Vector3[] vertices = new Vector3[4];

        vertices[0] = new Vector3(-1, 1, 0);
        vertices[1] = new Vector3(1, 1, 0);
        vertices[2] = new Vector3(1, -1, 0);
        vertices[3] = new Vector3(-1, -1, 0);

        int[] triangles = new int[] { 0, 1, 3, 3, 1, 2 };

        Color[] colors = new Color[4];

        Color rand = Random.ColorHSV();

        colors[0] = Random.ColorHSV();
        colors[1] = Random.ColorHSV();
        colors[2] = Random.ColorHSV();
        colors[3] = Random.ColorHSV();

        mesh.vertices = vertices;
        mesh.triangles = triangles;
        mesh.colors = colors;

        mesh.RecalculateNormals();
        mesh.RecalculateTangents();
	}
	
}
