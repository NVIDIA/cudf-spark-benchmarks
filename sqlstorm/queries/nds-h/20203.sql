WITH RankedSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_sales
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
), 
SupplierCounts AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p 
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
), 
NationRegions AS (
    SELECT 
        n.n_nationkey,
        r.r_regionkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_in_region
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, r.r_regionkey
)
SELECT 
    o.o_orderkey,
    RS.total_sales,
    COALESCE(SC.supplier_count, 0) AS supplier_count,
    NR.supplier_in_region,
    CASE 
        WHEN o.o_orderstatus = 'O' THEN 'Open'
        ELSE 'Closed'
    END AS order_status,
    CASE 
        WHEN (total_sales > 10000 AND supplier_count > 1) OR NR.supplier_in_region IS NULL THEN 'High Value'
        ELSE 'Regular Value'
    END AS order_value_category
FROM 
    orders o
LEFT JOIN 
    RankedSales RS ON o.o_orderkey = RS.l_orderkey
LEFT JOIN 
    SupplierCounts SC ON RS.l_orderkey = SC.p_partkey
LEFT JOIN 
    NationRegions NR ON o.o_custkey = NR.n_nationkey 
WHERE 
    (o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31' OR 
     o.o_orderpriority = 'High')
    AND (RS.total_sales IS NOT NULL OR o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_returnflag = 'R'))
ORDER BY 
    o.o_orderkey;