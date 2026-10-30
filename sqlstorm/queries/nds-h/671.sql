WITH DiscountedSales AS (
    SELECT 
        l_orderkey, 
        SUM(l_extendedprice * (1 - l_discount)) AS total_discounted_price,
        l_returnflag,
        l_linestatus,
        COUNT(*) AS item_count
    FROM 
        lineitem
    GROUP BY 
        l_orderkey, l_returnflag, l_linestatus
), SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), RegionSales AS (
    SELECT 
        n.n_name AS nation_name, 
        SUM(ds.total_discounted_price) AS total_sales
    FROM 
        DiscountedSales ds
        JOIN orders o ON ds.l_orderkey = o.o_orderkey
        JOIN customer c ON o.o_custkey = c.c_custkey
        JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        n.n_name
), NullFilteredRegions AS (
    SELECT 
        r.r_name,
        COALESCE(rs.total_sales, 0) AS total_sales
    FROM 
        region r
        LEFT JOIN RegionSales rs ON r.r_name = rs.nation_name
)
SELECT 
    rfr.r_name,
    rfr.total_sales,
    sr.total_supply_cost,
    (rfr.total_sales / NULLIF(sr.total_supply_cost, 0)) AS sales_per_cost_ratio
FROM 
    NullFilteredRegions rfr
LEFT JOIN 
    SupplierInfo sr ON rfr.total_sales > 0
ORDER BY 
    sales_per_cost_ratio DESC
LIMIT 10;