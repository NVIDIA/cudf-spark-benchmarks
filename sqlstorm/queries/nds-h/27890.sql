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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rnk
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
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
        n.n_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name LIKE '%land%'
),
CustomerCounts AS (
    SELECT 
        c.c_nationkey,
        COUNT(c.c_custkey) AS total_customers
    FROM customer c
    GROUP BY c.c_nationkey
),
TopRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(cc.total_customers) AS customer_sum
    FROM region r
    JOIN CustomerCounts cc ON r.r_regionkey = cc.c_nationkey
    GROUP BY r.r_regionkey, r.r_name
    ORDER BY customer_sum DESC
    LIMIT 5
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    sd.s_name AS supplier_name,
    sd.s_address AS supplier_address,
    tr.r_name AS region_name
FROM RankedParts rp
JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN supplier sd ON ps.ps_suppkey = sd.s_suppkey
JOIN TopRegions tr ON sd.s_nationkey = tr.r_regionkey
WHERE rp.rnk <= 10
ORDER BY rp.p_retailprice DESC;
