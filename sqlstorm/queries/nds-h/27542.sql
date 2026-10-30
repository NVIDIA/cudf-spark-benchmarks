
WITH RankedProducts AS (
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
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS price_rank
    FROM
        part p
    WHERE
        p.p_retailprice > 100
),
RegionSupplierCount AS (
    SELECT
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM
        region r
    JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY
        r.r_name
),
CustomerOrderSummary AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
    HAVING
        SUM(o.o_totalprice) > 5000
)
SELECT
    rp.p_name,
    rp.p_mfgr,
    rp.p_retailprice,
    rsc.r_name,
    rsc.supplier_count,
    cos.c_name,
    cos.total_spent
FROM
    RankedProducts rp
JOIN
    RegionSupplierCount rsc ON rp.p_brand = SUBSTRING(rsc.r_name, 1, 5) 
JOIN
    CustomerOrderSummary cos ON rp.p_partkey IN (
        SELECT l.l_partkey
        FROM lineitem l
        JOIN orders o ON l.l_orderkey = o.o_orderkey
        WHERE o.o_orderstatus = 'O'
    )
WHERE
    rp.price_rank <= 10
ORDER BY
    rp.p_retailprice DESC, rsc.supplier_count DESC;
