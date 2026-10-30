WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        n.n_name AS nation_name
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_suppkey = n.n_nationkey
    WHERE 
        rs.rank <= 3
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(hv.total_value), 0) AS total_order_value
    FROM 
        customer c
    LEFT JOIN 
        HighValueOrders hv ON c.c_custkey = hv.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    cs.total_order_value,
    ts.s_name AS top_supplier,
    ts.s_acctbal
FROM 
    CustomerOrders cs
LEFT JOIN 
    TopSuppliers ts ON cs.total_order_value > 5000 
                    AND cs.c_custkey IN (
                        SELECT c.c_custkey 
                        FROM customer c 
                        WHERE c.c_nationkey = (
                            SELECT n.n_nationkey 
                            FROM nation n 
                            JOIN supplier s ON n.n_nationkey = s.s_nationkey 
                            WHERE s.s_acctbal > 10000
                            LIMIT 1
                        )
                    )
ORDER BY 
    cs.total_order_value DESC, 
    ts.s_acctbal DESC;

