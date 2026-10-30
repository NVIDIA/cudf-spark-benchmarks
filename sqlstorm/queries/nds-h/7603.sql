WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as price_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_cost DESC
    LIMIT 10
),
CustomerSpend AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    rs.o_orderkey,
    rs.o_totalprice,
    rs.o_orderdate,
    ts.s_name AS top_supplier_name,
    cs.c_name AS customer_name,
    cs.total_spent
FROM RankedOrders rs
JOIN TopSuppliers ts ON ts.total_supply_cost > 10000
JOIN CustomerSpend cs ON cs.total_spent > 5000
WHERE rs.price_rank <= 5
ORDER BY rs.o_totalprice DESC, ts.total_supply_cost ASC;