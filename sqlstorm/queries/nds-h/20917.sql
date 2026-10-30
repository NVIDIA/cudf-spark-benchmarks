
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL 
        AND LENGTH(p.p_name) > 10
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        MAX(s.s_acctbal) AS max_acctbal
    FROM 
        supplier s
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(s.s_acctbal) > 10000
), 
CustomerStats AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
)
SELECT 
    p.p_name,
    p.p_brand,
    COUNT(DISTINCT lt.l_orderkey) AS total_sales,
    SUM(lt.l_extendedprice * (1 - lt.l_discount)) AS total_revenue,
    CASE 
        WHEN SUM(lt.l_extendedprice * (1 - lt.l_discount)) > 50000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category,
    cs.total_orders,
    cs.avg_order_value
FROM 
    RankedParts p
LEFT JOIN 
    lineitem lt ON p.p_partkey = lt.l_partkey
LEFT JOIN 
    SupplierDetails sd ON sd.max_acctbal > 50000
LEFT JOIN 
    CustomerStats cs ON cs.c_nationkey = 
        (SELECT n.n_nationkey 
         FROM nation n 
         WHERE n.n_name IN ('USA', 'CANADA') 
         LIMIT 1)
WHERE 
    p.rn <= 5
GROUP BY 
    p.p_name, 
    p.p_brand, 
    cs.total_orders, 
    cs.avg_order_value
HAVING 
    COUNT(DISTINCT lt.l_orderkey) IS NOT NULL 
    AND (SUM(lt.l_extendedprice * (1 - lt.l_discount)) > 1000 OR cs.total_orders > 10)
ORDER BY 
    total_revenue DESC, 
    total_sales ASC
LIMIT 10 OFFSET 5;
