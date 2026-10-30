
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS number_of_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
NationStatistics AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(s.s_suppkey) AS suppliers_count,
        SUM(s.s_acctbal) AS total_accounts
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name,
    SUM(cos.total_spent) AS total_spending,
    ns.suppliers_count,
    ns.total_accounts
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    CustomerOrderStats cos ON n.n_nationkey = cos.c_custkey
LEFT JOIN 
    NationStatistics ns ON n.n_nationkey = ns.n_nationkey
WHERE 
    n.n_name IS NOT NULL AND 
    (ns.suppliers_count > 0 OR ns.total_accounts IS NOT NULL)
GROUP BY 
    r.r_name, ns.suppliers_count, ns.total_accounts
HAVING 
    SUM(cos.total_spent) > (SELECT AVG(total_spent) FROM CustomerOrderStats)
ORDER BY 
    total_spending DESC;
