WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, p.p_type
),
TopPart AS (
    SELECT 
        tp.p_partkey,
        tp.p_name,
        tp.p_brand,
        tp.p_retailprice,
        tp.supplier_count,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        RankedParts tp
    JOIN 
        supplier s ON tp.p_partkey = s.s_nationkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        tp.rank <= 5
)
SELECT 
    tp.p_partkey,
    tp.p_name,
    tp.p_brand,
    tp.p_retailprice,
    tp.supplier_count,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(o.o_totalprice) AS avg_revenue,
    MAX(o.o_orderdate) AS latest_order_date
FROM 
    TopPart tp
LEFT JOIN 
    lineitem l ON tp.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    tp.p_partkey, tp.p_name, tp.p_brand, tp.p_retailprice, tp.supplier_count
ORDER BY 
    total_revenue DESC
LIMIT 10;
