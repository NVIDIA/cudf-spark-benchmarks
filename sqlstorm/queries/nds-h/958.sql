WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        n.n_name
),
TopNations AS (
    SELECT 
        nation_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
),
PartSupplierCount AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
EligibleParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        pc.supplier_count
    FROM 
        part p
    LEFT JOIN 
        PartSupplierCount pc ON p.p_partkey = pc.ps_partkey
    WHERE 
        p.p_retailprice > 100.00 
        AND (pc.supplier_count IS NULL OR pc.supplier_count < 3)
)
SELECT 
    t.nation_name,
    ep.p_partkey,
    ep.p_name,
    ep.p_brand,
    ep.p_retailprice
FROM 
    TopNations t
JOIN 
    EligibleParts ep ON t.sales_rank <= 5
ORDER BY 
    t.nation_name, ep.p_retailprice DESC;