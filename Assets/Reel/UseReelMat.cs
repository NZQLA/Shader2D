using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

[RequireComponent(typeof(Image))]
public class UseReelMat : MonoBehaviour
{
    public bool bInverse = false;
    public Material _matReel;
    public Image img;


    private void Awake()
    {
        if (img == null)
        {
            img = GetComponent<Image>();
        }

        _matReel = img.material;
    }


    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.R))
        {
            ActionReel();
        }
    }


    [ContextMenu("Reel")]
    void ActionReel()
    {
		Debug.Log("ActionReel");
        if (_matReel != null)
        {
            // 设置开启开关
            _matReel.SetFloat("_ActionSwitch",1);

            // 设置起始时间
            _matReel.SetFloat("_TimeStart", Time.timeSinceLevelLoad);

            // 设置逆向开关
            _matReel.SetFloat("_InverseToggel", bInverse ? 1 : 0);

        }
    }




}
