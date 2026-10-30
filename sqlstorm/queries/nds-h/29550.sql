WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_comment LIKE '%special%'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name IN (SELECT DISTINCT r_name FROM region WHERE r_comment LIKE '%important%')
),
TopSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.s_acctbal,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM SupplierDetails sd
    JOIN partsupp ps ON sd.s_suppkey = ps.ps_suppkey
    GROUP BY sd.s_suppkey, sd.s_name, sd.s_acctbal
    HAVING SUM(ps.ps_supplycost) > 1000
)
SELECT 
    rp.p_partkey, 
    rp.p_name,
    rp.p_brand,
    ts.s_name AS supplier_name,
    ts.total_supply_cost,
    CASE 
        WHEN rp.price_rank <= 3 THEN 'Top Price'
        ELSE 'Other'
    END AS price_category
FROM RankedParts rp
JOIN TopSuppliers ts ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ts.s_suppkey)
WHERE rp.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
ORDER BY rp.p_retailprice DESC, ts.total_supply_cost DESC;
