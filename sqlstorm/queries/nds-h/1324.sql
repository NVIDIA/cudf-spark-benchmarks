WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
        JOIN orders o ON l.l_orderkey = o.o_orderkey
        JOIN customer c ON o.o_custkey = c.c_custkey
        JOIN nation n ON c.c_nationkey = n.n_nationkey
        JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        n.n_name, r.r_name
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
RankedSales AS (
    SELECT 
        nation_name,
        region_name,
        total_sales,
        RANK() OVER (PARTITION BY region_name ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
)
SELECT 
    rs.nation_name,
    rs.region_name,
    rs.total_sales,
    sd.s_name AS supplier_name,
    sd.total_supply_cost,
    COALESCE(sd.total_supply_cost / NULLIF(rs.total_sales, 0), 0) AS cost_to_sales_ratio
FROM 
    RankedSales rs
LEFT JOIN 
    SupplierDetails sd ON rs.region_name = sd.s_name
WHERE 
    rs.sales_rank <= 5
ORDER BY 
    rs.region_name, rs.total_sales DESC;