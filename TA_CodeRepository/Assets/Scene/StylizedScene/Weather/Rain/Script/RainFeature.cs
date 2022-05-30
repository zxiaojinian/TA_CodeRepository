using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class RainFeature : ScriptableRendererFeature
{
    class RainSplashPass : ScriptableRenderPass
    {
        const string CMDSTR = "Rain Splash";
        Mesh rainSplashMesh;
        MaterialPropertyBlock mMPB;
        int id_RainSplashPosX;
        int id_RainSplashPosZ;

        public RainSplashPass()
        {
            mMPB = new MaterialPropertyBlock();
            id_RainSplashPosX = Shader.PropertyToID("_RainSplashPosX");
            id_RainSplashPosZ = Shader.PropertyToID("_RainSplashPosZ");
        }

        public void Setup(Mesh rainSplashMeshPra)
        {
            rainSplashMesh = rainSplashMeshPra;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            try
            {
                CommandBuffer cmd = CommandBufferPool.Get(CMDSTR);
                mMPB.Clear();
                Matrix4x4[] matrices = new Matrix4x4[RainCtrl.Instance.RainSplashPosArr.Count];
                float[] posXArr = new float[RainCtrl.Instance.RainSplashPosArr.Count];
                float[] posZArr = new float[RainCtrl.Instance.RainSplashPosArr.Count];
                for (int i = 0; i < RainCtrl.Instance.RainSplashPosArr.Count; i++)
                {
                    matrices[i] = Matrix4x4.identity;
                    posXArr[i] = RainCtrl.Instance.RainSplashPosArr[i].posX;
                    posZArr[i] = RainCtrl.Instance.RainSplashPosArr[i].posZ;
                }
                mMPB.SetFloatArray(id_RainSplashPosX, posXArr);
                mMPB.SetFloatArray(id_RainSplashPosZ, posZArr);
                cmd.DrawMeshInstanced(rainSplashMesh, 0, RainCtrl.Instance.RainMaterial, 0, matrices, RainCtrl.Instance.RainSplashPosArr.Count, mMPB);
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }
            catch (System.Exception e)
            {
                Debug.LogError("RainSplashPass is error" + e);
            }
        }
    }

    class RainMaskPass : ScriptableRenderPass
    {
        const string CMDSTR = "RainMask";
        RenderTargetHandle rainMaskTexture;
        Mesh postProcessingMesh;

        public RainMaskPass()
        {
            rainMaskTexture.Init("_RainMaskTexture");
        }

        public void Setup(Mesh ppMesh)
        {
            postProcessingMesh = ppMesh;
        }

        RenderTextureDescriptor GetDescriptor(int width, int height)
        {
            RenderTextureDescriptor desc = new RenderTextureDescriptor(width, height);
            desc.msaaSamples = 1;
            desc.depthBufferBits = 0;
            desc.colorFormat = RenderTextureFormat.ARGB32;
            desc.useMipMap = false;
            desc.sRGB = false;
            return desc;
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            base.Configure(cmd, cameraTextureDescriptor);
            RenderTextureDescriptor desc = GetDescriptor((int)(cameraTextureDescriptor.width * 0.25f), (int)(cameraTextureDescriptor.height * 0.25f));
            cmd.GetTemporaryRT(rainMaskTexture.id, desc, FilterMode.Bilinear);
            ConfigureClear(ClearFlag.All, Color.clear);
            ConfigureTarget(rainMaskTexture.id);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            try
            {
                CommandBuffer cmd = CommandBufferPool.Get(CMDSTR);
                Matrix4x4 matrix = Matrix4x4.identity;
                Camera curCam = renderingData.cameraData.camera;
                matrix.SetTRS(curCam.transform.position, Quaternion.Euler(-90f, 0f, 0f), Vector3.one);
                cmd.DrawMesh(postProcessingMesh, matrix, RainCtrl.Instance.RainMaterial, 0, 1);
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }
            catch (System.Exception e)
            {
                Debug.LogError("RainMaskPass is error" + e);
            }
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(rainMaskTexture.id);
        }
    }

    class RainMergePass : ScriptableRenderPass
    {
        const string CMDSTR = "Rain Merge";
        Mesh postProcessingMesh;

        public void Setup(Mesh ppMesh)
        {
            postProcessingMesh = ppMesh;
        }


        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            try
            {
                CommandBuffer cmd = CommandBufferPool.Get(CMDSTR);
                Matrix4x4 matrix = Matrix4x4.identity;
                Camera curCam = renderingData.cameraData.camera;
                matrix.SetTRS(curCam.transform.position, Quaternion.Euler(-90f, 0f, 0f), Vector3.one);
                cmd.DrawMesh(postProcessingMesh, matrix, RainCtrl.Instance.RainMaterial, 0, 2);
                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }
            catch(System.Exception e)
            {
                Debug.LogError("RainMergePass is error" + e);
            }
        }
    }

    public Mesh RainPostProcessingMesh;
    public Mesh RainSplashMesh;

    RainSplashPass rainSplashPass;
    RainMaskPass rainMaskPass;
    RainMergePass mRainMergePass;
    const string rainSceneDepthRenderStr = "RainSceneDepthRender";

    public override void Create()
    {
        if (RainPostProcessingMesh == null) Debug.LogError("RainPostProcessingMesh Is Null!");
        if (RainSplashMesh == null) Debug.LogError("RainSplashMesh Is NUll!");

        rainSplashPass = new RainSplashPass
        {
            renderPassEvent = RenderPassEvent.AfterRenderingOpaques
        };

        rainMaskPass = new RainMaskPass
        {
            renderPassEvent = RenderPassEvent.AfterRenderingTransparents
        };
        mRainMergePass = new RainMergePass
        {
            renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing
        };
#if UNITY_EDITOR
        RainSceneDepthRenderData rainSceneDepthRender = PipelineUtilities.GetRenderer<RainSceneDepthRenderData>(rainSceneDepthRenderStr, nameof(RainSceneDepthRenderData));
        PipelineUtilities.ValidatePipelineRenderers(rainSceneDepthRender);
#endif
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (RainCtrl.Instance == null || !RainCtrl.Instance.enabled || RainCtrl.Instance.RainMaterial == null) return;

        bool mainGameCam = renderingData.cameraData.camera.cameraType == CameraType.Game && renderingData.cameraData.camera == Camera.main;
        if (mainGameCam || renderingData.cameraData.camera.cameraType == CameraType.SceneView)
        {
            if (RainCtrl.Instance.EnableRainSplash && RainCtrl.Instance.RainSplashPosArr.Count > 0 && RainSplashMesh != null)
            {
                rainSplashPass.Setup(RainSplashMesh);
                renderer.EnqueuePass(rainSplashPass);
            }

            if (RainPostProcessingMesh != null)
            {
                rainMaskPass.Setup(RainPostProcessingMesh);
                renderer.EnqueuePass(rainMaskPass);
                mRainMergePass.Setup(RainPostProcessingMesh);
                renderer.EnqueuePass(mRainMergePass);
            }
        }
    }
}
