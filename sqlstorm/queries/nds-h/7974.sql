WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
), TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
        JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100.00
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        SUM(ps.ps_availqty) > 500
), RegionalCustomerSpend AS (
    SELECT 
        n.n_nationkey,
        SUM(o.o_totalprice) AS total_spend,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        customer c
        JOIN nation n ON c.c_nationkey = n.n_nationkey
        JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_nationkey
)
SELECT 
    r.r_name AS region_name,
    SUM(rc.total_spend) AS total_spend,
    AVG(rc.customer_count) AS avg_customer_count,
    ts.total_supply_cost AS supplier_cost
FROM 
    region r
    LEFT JOIN RegionalCustomerSpend rc ON r.r_regionkey = rc.n_nationkey
    LEFT JOIN TopSuppliers ts ON TRUE
GROUP BY 
    r.r_name, ts.total_supply_cost
ORDER BY 
    total_spend DESC, supplier_cost DESC
LIMIT 10;