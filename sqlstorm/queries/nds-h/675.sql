
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rnk <= 3
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_linenumber) AS items_count,
        o.o_orderstatus
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
OrderSummary AS (
    SELECT 
        od.o_orderstatus,
        COUNT(od.o_orderkey) AS total_orders,
        SUM(od.revenue) AS total_revenue,
        AVG(od.items_count) AS avg_items
    FROM 
        OrderDetails od
    GROUP BY 
        od.o_orderstatus
)
SELECT 
    n.n_name AS nation_name,
    COALESCE(SUM(ts.s_acctbal), 0) AS total_supplier_balance,
    SUM(os.total_revenue) AS total_sales_revenue,
    AVG(os.avg_items) AS average_items_per_order
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey 
LEFT JOIN 
    TopSuppliers ts ON s.s_suppkey = ts.s_suppkey
LEFT JOIN 
    OrderSummary os ON n.n_nationkey = (
        SELECT 
            c.c_nationkey 
        FROM 
            customer c 
        JOIN 
            orders o ON c.c_custkey = o.o_custkey 
        WHERE 
            o.o_orderkey IN (
                SELECT l.l_orderkey 
                FROM lineitem l
                WHERE l.l_returnflag = 'N'
            )
        GROUP BY 
            c.c_nationkey
        LIMIT 1
    )
GROUP BY 
    n.n_name
ORDER BY 
    total_supplier_balance DESC, total_sales_revenue DESC;
