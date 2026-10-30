WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
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
RankedSales AS (
    SELECT 
        nation_name, 
        total_sales, 
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
), 
TopNations AS (
    SELECT 
        nation_name,
        total_sales,
        order_count
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
), 
SupplierStats AS (
    SELECT 
        s.s_name AS supplier_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
), 
Combined AS (
    SELECT 
        tn.nation_name, 
        tn.total_sales, 
        tn.order_count, 
        ss.supplier_name, 
        ss.part_count, 
        ss.total_supply_cost
    FROM 
        TopNations tn
    FULL OUTER JOIN 
        SupplierStats ss ON tn.nation_name = (CASE WHEN ss.supplier_name IS NOT NULL THEN 
                                                        CONCAT('Supplier of ', ss.supplier_name) 
                                                    ELSE 'Unknown Supplier' END)
)
SELECT 
    c.nation_name,
    c.total_sales,
    COALESCE(c.order_count, 0) AS total_orders,
    COALESCE(c.supplier_name, 'No Supplier') AS supplier_name,
    COALESCE(c.part_count, 0) AS parts_supplied,
    COALESCE(c.total_supply_cost, 0) AS total_cost,
    CASE 
        WHEN c.total_sales >= 1000000 THEN 'High Revenue'
        WHEN c.total_sales BETWEEN 500000 AND 999999 THEN 'Moderate Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    Combined c
WHERE 
    c.total_sales IS NOT NULL
    OR c.supplier_name IS NOT NULL
ORDER BY 
    c.total_sales DESC, c.nation_name;