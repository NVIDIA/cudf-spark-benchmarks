WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        DENSE_RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_orderdate >= DATE '1995-01-01' AND 
        o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_sold
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1995-01-01' AND 
        l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    rc.c_name,
    rc.total_spent,
    hvs.s_name AS high_value_supplier,
    pd.p_name AS popular_part,
    pd.total_sold
FROM 
    RankedCustomers rc
LEFT JOIN 
    HighValueSuppliers hvs ON rc.spending_rank = 1
LEFT JOIN 
    PartDetails pd ON pd.total_sold = (SELECT MAX(total_sold) FROM PartDetails)
ORDER BY 
    rc.total_spent DESC, 
    pd.total_sold DESC;