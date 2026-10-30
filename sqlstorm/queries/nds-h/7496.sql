
WITH PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
OrderDetails AS (
    SELECT 
        li.l_orderkey,
        COUNT(li.l_linenumber) AS total_lines,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        SUM(li.l_tax) AS total_tax
    FROM 
        lineitem li
    JOIN 
        orders o ON li.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        li.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        li.l_orderkey
),
SupplierRegion AS (
    SELECT 
        s.s_suppkey,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(s.s_acctbal) AS total_acct_bal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_suppkey, n.n_name, r.r_name
)
SELECT 
    ps.ps_partkey,
    ps.total_available_qty,
    ps.avg_supply_cost,
    od.total_lines,
    od.total_revenue,
    od.total_tax,
    sr.nation_name,
    sr.region_name,
    sr.total_acct_bal
FROM 
    PartSupplier ps
JOIN 
    OrderDetails od ON ps.ps_partkey = od.l_orderkey
JOIN 
    SupplierRegion sr ON ps.ps_partkey = sr.s_suppkey
ORDER BY 
    ps.total_available_qty DESC, 
    od.total_revenue DESC
LIMIT 100;
