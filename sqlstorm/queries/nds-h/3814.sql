WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
NationalSales AS (
    SELECT 
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_nationkey
),
FinalResults AS (
    SELECT 
        p.p_name,
        p.p_size,
        r.r_name AS region,
        total_cost,
        ns.total_sales,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        SupplierCost sc ON p.p_partkey = sc.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        NationalSales ns ON n.n_nationkey = ns.c_nationkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    GROUP BY 
        p.p_partkey, p.p_name, p.p_size, r.r_name, total_cost, ns.total_sales
    HAVING 
        COUNT(DISTINCT s.s_suppkey) > 0
)
SELECT 
    f.region,
    f.p_name,
    f.p_size,
    COALESCE(f.total_cost, 0) AS total_cost,
    COALESCE(f.total_sales, 0) AS total_sales,
    f.supplier_count
FROM 
    FinalResults f
ORDER BY 
    f.region, f.p_name;
