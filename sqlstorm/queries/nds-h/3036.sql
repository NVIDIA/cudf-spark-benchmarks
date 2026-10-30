WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
), PartSupplierSummary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), RegionExpense AS (
    SELECT 
        n.n_nationkey,
        SUM(o.o_totalprice) AS total_expense
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_nationkey
)
SELECT 
    r.r_name, 
    COALESCE(SUM(re.total_expense), 0) AS total_expense,
    COALESCE(SUM(psu.total_available), 0) AS total_available,
    COALESCE(AVG(psu.avg_supply_cost), 0) AS avg_supply_cost_per_part
FROM 
    region r
LEFT JOIN 
    RegionExpense re ON r.r_regionkey = re.n_nationkey
LEFT JOIN 
    PartSupplierSummary psu ON psu.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size < 20)
GROUP BY 
    r.r_name
HAVING 
    COALESCE(SUM(re.total_expense), 0) > 10000
ORDER BY 
    total_expense DESC;
