
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY np.n_regionkey ORDER BY s.s_acctbal DESC) AS rank,
        np.n_regionkey
    FROM 
        supplier s
    JOIN 
        nation np ON s.s_nationkey = np.n_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > (
            SELECT 
                AVG(l2.l_extendedprice * (1 - l2.l_discount))
            FROM 
                lineitem l2
            WHERE 
                l2.l_shipdate <= '1998-10-01'
        )
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('F', 'P')
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_linenumber) AS line_count,
        SUM(l.l_quantity) AS total_quantity,
        MAX(l.l_extendedprice) AS max_line_price,
        MAX(CASE WHEN l.l_discount IS NOT NULL THEN l.l_discount ELSE 0 END) AS max_discount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    DISTINCT np.r_name,
    rs.s_name,
    COALESCE(tc.total_spent, 0) AS total_spending,
    COUNT(od.o_orderkey) AS order_count,
    SUM(od.total_quantity) / NULLIF(COUNT(od.o_orderkey), 0) AS avg_quantity_per_order,
    MAX(od.max_discount) AS highest_discount,
    (SELECT COUNT(*) FROM lineitem l WHERE l.l_returnflag = 'R') AS total_returns
FROM 
    region np
LEFT JOIN 
    RankedSuppliers rs ON np.r_regionkey = rs.n_regionkey AND rs.rank <= 5
LEFT JOIN 
    TopCustomers tc ON tc.customer_rank <= 10
LEFT JOIN 
    OrderDetails od ON od.o_orderkey IN (SELECT o.o_orderkey FROM orders o)
GROUP BY 
    np.r_name, rs.s_name, tc.total_spent
ORDER BY 
    np.r_name ASC, total_spending DESC;
