WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1995-02-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    os.o_orderkey,
    os.o_orderdate,
    os.total_sales,
    os.unique_suppliers,
    os.unique_parts,
    sd.s_name AS supplier_name,
    sd.nation_name,
    sd.region_name
FROM 
    OrderSummary os
JOIN 
    lineitem l ON os.o_orderkey = l.l_orderkey
JOIN 
    SupplierDetails sd ON l.l_suppkey = sd.s_suppkey
ORDER BY 
    os.total_sales DESC, 
    os.o_orderdate ASC
LIMIT 100;