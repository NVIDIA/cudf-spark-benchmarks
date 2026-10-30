
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        DENSE_RANK() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_brand IS NOT NULL)
),
TotalSalesByNation AS (
    SELECT 
        n.n_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_nationkey
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_size,
    ts.total_sales,
    sa.total_avail_qty,
    CASE 
        WHEN ts.total_sales IS NULL OR sa.total_avail_qty IS NULL THEN 'Insufficient Data'
        WHEN ts.total_sales / NULLIF(sa.total_avail_qty, 0) > 1 THEN 'High Demand'
        ELSE 'Normal Demand'
    END AS demand_status
FROM 
    RankedParts rp
LEFT JOIN 
    TotalSalesByNation ts ON ts.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')  
LEFT JOIN 
    SupplierAvailability sa ON sa.ps_partkey = rp.p_partkey
WHERE 
    rp.price_rank = 1 
    AND (rp.p_size BETWEEN 10 AND 20 OR rp.p_name LIKE '%fragile%')
ORDER BY 
    rp.p_retailprice DESC, 
    demand_status DESC;
