WITH  CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) as order_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate IS NOT NULL
), OrderDetails AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.o_orderkey,
        co.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_amount,
        COUNT(DISTINCT l.l_partkey) AS unique_parts_sold
    FROM 
        CustomerOrders co
    JOIN 
        lineitem l ON co.o_orderkey = l.l_orderkey
    WHERE 
        co.order_rank <= 5 
    GROUP BY 
        co.c_custkey, co.c_name, co.o_orderkey, co.o_orderdate
), SupplierEfficiency AS (
    SELECT 
        ps.ps_partkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(CASE 
                WHEN s.s_nationkey IS NULL THEN 0 
                ELSE 1 END) AS supplied_nations
    FROM 
        partsupp ps
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
), RegionSales AS (
    SELECT 
        n.n_regionkey,
        SUM(od.total_order_amount) AS total_sales,
        COUNT(DISTINCT od.o_orderkey) AS order_count
    FROM 
        OrderDetails od
    JOIN 
        customer c ON od.c_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_regionkey
)
SELECT 
    r.r_name,
    rs.total_sales,
    CASE 
        WHEN rs.total_sales IS NULL THEN 'No Sales' 
        ELSE 'Sales Exist' END AS sales_status,
    COALESCE(rs.order_count, 0) AS orders_in_region
FROM 
    region r
LEFT JOIN 
    RegionSales rs ON r.r_regionkey = rs.n_regionkey
ORDER BY 
    r.r_name, rs.total_sales DESC
LIMIT 10;