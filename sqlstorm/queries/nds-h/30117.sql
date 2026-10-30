WITH  RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
), 
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS lineitem_count,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierDetails AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        partsupp ps ON n.n_nationkey = ps.ps_suppkey
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    os.o_orderkey,
    os.total_sales,
    os.lineitem_count,
    ss.s_name,
    ss.s_acctbal,
    sd.region,
    sd.nation,
    sd.part_count
FROM 
    OrderSummary os
LEFT JOIN 
    RankedSuppliers ss ON ss.rank = 1
LEFT JOIN 
    SupplierDetails sd ON sd.part_count > 5
WHERE 
    os.total_sales > (SELECT AVG(total_sales) FROM OrderSummary)
AND 
    ss.s_acctbal IS NOT NULL
ORDER BY 
    os.total_sales DESC
LIMIT 100;
