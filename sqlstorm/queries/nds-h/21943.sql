
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.p_brand) AS brand_count
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice < 1000)
),
CustomerSpend AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 5000
),
SupplementedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        COALESCE(lp.l_extendedprice, 0) AS last_price,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finalized'
            ELSE 'Pending'
        END AS order_status
    FROM 
        orders o
    LEFT JOIN 
        lineitem lp ON o.o_orderkey = lp.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
SignificantNations AS (
    SELECT 
        n.n_name,
        SUM(s.s_acctbal) AS total_bal,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    WHERE 
        n.n_comment IS NOT NULL
    GROUP BY 
        n.n_name
    HAVING 
        SUM(s.s_acctbal) IS NOT NULL AND SUM(s.s_acctbal) > 100000
    ORDER BY 
        total_bal DESC
)
SELECT 
    rp.p_name,
    cs.total_spent,
    cs.order_count,
    so.o_orderdate,
    so.order_status,
    sn.n_name,
    sn.total_bal,
    sn.unique_suppliers
FROM 
    RankedParts rp
JOIN 
    CustomerSpend cs ON cs.order_count > 1
JOIN 
    SupplementedOrders so ON so.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
JOIN 
    SignificantNations sn ON sn.unique_suppliers > (SELECT COUNT(*) FROM supplier) / 10
WHERE 
    rp.rn <= 5
    AND rp.p_retailprice > (SELECT AVG(p_retailprice) FROM part WHERE p_size <= 10)
    OR (rp.p_partkey IS NULL AND sn.total_bal IS NOT NULL)
ORDER BY 
    rp.p_retailprice DESC, 
    cs.total_spent DESC;
