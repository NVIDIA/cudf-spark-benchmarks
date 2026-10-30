WITH RankedParts AS (
    SELECT 
        p.p_name,
        p.p_brand,
        s.s_name AS supplier_name,
        COUNT(DISTINCT l.l_orderkey) AS order_count,
        SUM(l.l_extendedprice) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(l.l_extendedprice) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_name, p.p_brand, s.s_name
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.supplier_name,
    rp.order_count,
    rp.total_sales
FROM 
    RankedParts rp
WHERE 
    rp.rank <= 5
ORDER BY 
    rp.p_brand, rp.total_sales DESC;
