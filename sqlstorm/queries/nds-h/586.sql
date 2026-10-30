WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        DENSE_RANK() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_custkey,
        c.c_mktsegment
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '30 days'
),
SupplierDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        s.s_name,
        COALESCE(s.s_acctbal, 0) AS supplier_balance
    FROM 
        lineitem l
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    sd.s_name,
    SUM(sd.l_extendedprice * (1 - sd.l_discount)) AS net_revenue,
    COUNT(DISTINCT r.c_custkey) AS unique_customers,
    SUM(sd.l_quantity) AS total_quantity,
    MAX(sd.supplier_balance) AS highest_supplier_balance
FROM 
    RecentOrders r
LEFT JOIN 
    SupplierDetails sd ON r.o_orderkey = sd.l_orderkey
LEFT JOIN 
    RankedSuppliers rs ON sd.l_suppkey = rs.s_suppkey
WHERE 
    rs.rank <= 5 AND r.o_orderdate IS NOT NULL
GROUP BY 
    r.o_orderkey, r.o_orderdate, sd.s_name
ORDER BY 
    net_revenue DESC, r.o_orderdate ASC
LIMIT 10;