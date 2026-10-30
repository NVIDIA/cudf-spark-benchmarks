WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopNations AS (
    SELECT 
        n.n_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name
    ORDER BY 
        total_supply_cost DESC
    LIMIT 5
)
SELECT 
    rc.c_name AS customer_name,
    rc.total_spent,
    tn.n_name AS top_nation,
    tn.total_supply_cost
FROM 
    RankedCustomers rc
JOIN 
    TopNations tn ON rc.c_custkey IN (
        SELECT 
            o.o_custkey 
        FROM 
            orders o
        JOIN 
            lineitem l ON o.o_orderkey = l.l_orderkey
        WHERE 
            l.l_shipdate >= '1997-01-01' 
            AND l.l_shipdate < '1997-12-31'
    )
WHERE 
    rc.spending_rank <= 10
ORDER BY 
    rc.total_spent DESC;