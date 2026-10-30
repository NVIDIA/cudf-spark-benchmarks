
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_availqty) DESC) AS rank_by_avail_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
OrderDetail AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_partkey) AS item_count
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    COALESCE(SUM(cs.total_spent), 0) AS total_spent_by_customers,
    COALESCE(SUM(ss.total_avail_qty), 0) AS total_avail_quantity_by_suppliers,
    AVG(od.total_sales) AS avg_sales_per_order
FROM 
    nation n
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    CustomerOrders cs ON c.c_custkey = cs.c_custkey
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN part p ON ps.ps_partkey = p.p_partkey 
        WHERE p.p_type LIKE '%BRASS%'
        LIMIT 1
    )
LEFT JOIN 
    OrderDetail od ON od.l_orderkey = (
        SELECT o.o_orderkey
        FROM orders o
        WHERE o.o_orderstatus = 'F'
        ORDER BY o.o_orderdate DESC
        LIMIT 1
    )
GROUP BY 
    n.n_name
ORDER BY 
    total_customers DESC, nation_name;
