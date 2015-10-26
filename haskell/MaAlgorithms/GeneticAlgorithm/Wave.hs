{-# LANGUAGE GADTs #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE ScopedTypeVariables #-}

-- 遗传算法
-- 目标：求解z = (0.5-(sin(sqrt(x**2+y**2))**2-0.5)/(1+(0.001*(x**2+y**2))**2))的最大值


import Data.Bits
import Data.List
import qualified Data.Vector as V
import Data.STRef
import Control.Monad
import Control.Monad.Loops
import Control.Monad.Random
import Control.Monad.ST

data Gene dtype where
  MkGene :: (FiniteBits dtype, Bounded dtype) => dtype -> Gene dtype

deriving instance Show (dtype) => Show (Gene dtype)

data Genome dtype = MkGenome {
  geneX :: Gene dtype,
  geneY :: Gene dtype
  } deriving Show

type Probability = Double  -- The probability that crossover happens. [0.0, 1.0]

selectRandomRange :: (MonadRandom m, FiniteBits dtype) => dtype -> m (Int, Int)
selectRandomRange d = do
  [left, right] <- sort <$> (take 2 <$> getRandomRs (0, finiteBitSize d -1))
  return (left, right)

crossoverGene :: (MonadRandom m, Bounded dtype) => Gene dtype -> Gene dtype -> m (Gene dtype, Gene dtype)
crossoverGene (MkGene father) (MkGene mother) = do
  (left, right) <- selectRandomRange father
  let mask = shiftR (shiftL maxBound (left + finiteBitSize father - right - 1)) left
  let counterMask = complement mask
  return (MkGene (father .&. counterMask .|. mother .&. mask), MkGene (mother .&. counterMask .|. father .&. mask))


crossover :: (MonadRandom m, Bounded dtype) => Genome dtype -> Genome dtype -> Probability -> m (Genome dtype, Genome dtype)  -- Crossover makes two offsprings from two parents
crossover father mother prob = do
  rnd <- getRandomR (0.0, 1.0)
  if prob >= rnd then
    do
      let (fx, fy) = (geneX father, geneY father)
      let (mx, my) = (geneX mother, geneY mother)
      (fx', mx') <- crossoverGene fx mx
      (fy', my') <- crossoverGene fy my
      return (MkGenome fx' fy', MkGenome mx' my')
    else return (father, mother)

mutateGene :: (MonadRandom m, Bounded dtype) => Gene dtype -> m (Gene dtype)
mutateGene (MkGene gene) = do
  (left, right) <- selectRandomRange gene
  return $ MkGene $ runST $ do
    stRef <- newSTRef gene
    forM_ [left..right] $ \idx ->
      readSTRef stRef >>= writeSTRef stRef . flip complementBit idx
    readSTRef stRef

mutate :: (MonadRandom m, Bounded dtype) => Genome dtype -> Probability -> m (Genome dtype)
mutate MkGenome{..} prob = do
  [rnd0, rnd1] <- take 2 <$> getRandomRs (0.0, 1.0)
  newGeneX <- if prob >= rnd0 then mutateGene geneX else return geneX
  newGeneY <- if prob >= rnd1 then mutateGene geneY else return geneY
  return MkGenome { geneX=newGeneX, geneY=newGeneY }

-- 以下是专门用于求解本问题的非通用代码

type IntGene = Gene Int
type IntGenome = Genome Int

genomeToCoord :: IntGenome -> (Double, Double)
genomeToCoord MkGenome {..} =
  (geneToAxis geneX, geneToAxis geneY)
  where
    geneToAxis :: IntGene -> Double
    geneToAxis (MkGene d) = let
      numD = fromIntegral d
      -- TODO: 不太理解为什么一定要加类型限定
      numMinBound = fromIntegral (minBound :: Int)
      numMaxBound = fromIntegral (maxBound :: Int)
      in
        if d < 0 then -numD / numMinBound * 10 else numD / numMaxBound * 10

assess :: IntGenome -> Double
assess genome = let
  (x, y) = genomeToCoord genome
  in
  (0.5 - (sin (sqrt (x**2 + y**2))**2 - 0.5) / (1 + (0.001 * (x**2 + y**2)**2)))

-- 自动生成原始人口
populate :: forall m. (MonadRandom m) => Int -> m V.Vector IntGenome
populate num =
  replicateM num populateOne
  where
    populateOne :: m IntGenome
    populateOne = do
      [gx, gy] <- replicateM 2 $ getRandomR (minBound, maxBound)
      return MkGenome {geneX=MkGene gx, geneY=MkGene gy}

-- Check it out with map genomeToCoord <$> populate 3 :)

select :: (MonadRandom m) => V.Vector IntGenome -> m IntGenome
select genomes = do
  let assessments = V.map assess genomes
  thres <- getRandomR (0, sum assessments)
  return (pick thres genomes)
  where
    pick :: Double -> Double -> V.Vector IntGenome -> V.Vector Double -> IntGenome
    pick thres curr genomes assessments = runST $ do
      {
        
      } untilM $
      

main :: IO ()
main = undefined
