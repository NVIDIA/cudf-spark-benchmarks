WITH RankedParts AS (
  SELECT
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    p.p_type,
    p.p_size,
    p.p_container,
    p.p_retailprice,
    p.p_comment,
    ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
  FROM
    part p
),
SupplierCount AS (
  SELECT
    ps.ps_partkey,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
  FROM
    partsupp ps
  GROUP BY
    ps.ps_partkey
),
TopParts AS (
  SELECT
    rp.p_partkey,
    rp.p_name,
    rp.p_mfgr,
    rp.p_brand,
    rp.p_type,
    rp.p_size,
    rp.p_retailprice,
    rp.p_comment,
    sc.supplier_count
  FROM
    RankedParts rp
  JOIN
    SupplierCount sc ON rp.p_partkey = sc.ps_partkey
  WHERE
    rp.price_rank <= 5
)
SELECT
  CONCAT(tp.p_name, ' - ', tp.p_brand, ' [', tp.supplier_count, ' suppliers]') AS part_details,
  tp.p_retailprice,
  CASE
    WHEN tp.p_size < 10 THEN 'Small'
    WHEN tp.p_size BETWEEN 10 AND 20 THEN 'Medium'
    ELSE 'Large'
  END AS size_category
FROM
  TopParts tp
ORDER BY
  tp.p_retailprice DESC;
