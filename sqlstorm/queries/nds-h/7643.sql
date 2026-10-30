WITH OrderStats AS (
    SELECT 
        c.c_nationkey,
        n.n_name,
        SUM(o.o_totalprice) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY 
        c.c_nationkey, n.n_name
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        MIN(s.s_acctbal) AS min_supplier_balance,
        MAX(s.s_acctbal) AS max_supplier_balance
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
FinalReport AS (
    SELECT 
        os.n_name,
        os.total_revenue,
        os.order_count,
        ps.total_available_qty,
        ps.min_supplier_balance,
        ps.max_supplier_balance
    FROM 
        OrderStats os
    JOIN 
        PartSupplier ps ON ps.ps_partkey IN (
            SELECT 
                l.l_partkey 
            FROM 
                lineitem l 
            JOIN 
                orders o ON l.l_orderkey = o.o_orderkey
            WHERE 
                o.o_orderdate >= DATE '1997-01-01' 
                AND o.o_orderdate < DATE '1997-10-01'
        )
)
SELECT 
    n_name, 
    total_revenue, 
    order_count, 
    total_available_qty, 
    min_supplier_balance, 
    max_supplier_balance
FROM 
    FinalReport
ORDER BY 
    total_revenue DESC, 
    order_count DESC
LIMIT 10;