WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SalesByRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE l.l_shipdate BETWEEN '1996-01-01' AND '1997-01-01'
    GROUP BY n.n_nationkey, n.n_name, r.r_name
),
RankedSales AS (
    SELECT 
        total_sales,
        region_name,
        RANK() OVER (PARTITION BY region_name ORDER BY total_sales DESC) AS sales_rank
    FROM SalesByRegion
),
DynamicSupplierSales AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        rs.region_name,
        rs.total_sales
    FROM SupplierStats ss
    JOIN RankedSales rs ON ss.total_parts > 10 
    WHERE rs.sales_rank <= 5
)

SELECT 
    ds.s_name,
    ds.region_name,
    ds.total_sales,
    COALESCE(cs.total_orders, 0) AS total_orders,
    COALESCE(cs.total_spent, 0) AS total_spent
FROM DynamicSupplierSales ds
LEFT JOIN CustomerOrders cs ON ds.s_suppkey = cs.c_custkey
WHERE ds.total_sales IS NOT NULL
ORDER BY ds.region_name, ds.total_sales DESC;