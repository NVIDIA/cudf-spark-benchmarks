WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerNationalStats AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT c.c_custkey) AS total_customers,
        AVG(c.c_acctbal) AS avg_acct_balance
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_nationkey
)
SELECT 
    r.r_name,
    COALESCE(cp.total_customers, 0) AS total_customers,
    COALESCE(cp.avg_acct_balance, 0) AS avg_account_balance,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    MAX(sp.total_supply_cost) AS max_supply_cost
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    CustomerNationalStats cp ON n.n_nationkey = cp.c_nationkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    RankedOrders ro ON l.l_orderkey = ro.o_orderkey
LEFT JOIN 
    SupplierParts sp ON ps.ps_partkey = sp.ps_partkey
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name, cp.total_customers, cp.avg_acct_balance
ORDER BY 
    total_revenue DESC
LIMIT 10;