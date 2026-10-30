
WITH  CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        ROW_NUMBER() OVER (ORDER BY SUM(c.c_acctbal) DESC) AS nation_rank
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        COUNT(c.c_custkey) > 5
),
FilteredPart AS (
    SELECT 
        p.p_partkey, 
        p.p_name,
        CASE 
            WHEN p.p_retailprice > 100 THEN 'High'
            WHEN p.p_retailprice BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS price_category
    FROM 
        part p
    WHERE 
        p.p_size IS NOT NULL
)
SELECT 
    co.c_custkey,
    co.c_name,
    p.p_name,
    psd.total_available,
    psd.avg_supply_cost,
    tn.n_name AS top_nation,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_value,
    (CASE 
        WHEN COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) > 1000 THEN 'Big Spender' 
        ELSE 'Regular Shopper' 
     END) AS shopper_category
FROM 
    CustomerOrderSummary co
LEFT JOIN 
    lineitem l ON co.c_custkey = l.l_orderkey
JOIN 
    FilteredPart p ON p.p_partkey = l.l_partkey
JOIN 
    PartSupplierDetails psd ON p.p_partkey = psd.ps_partkey
JOIN 
    TopNations tn ON co.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = tn.n_nationkey)
GROUP BY 
    co.c_custkey, co.c_name, p.p_name, psd.total_available, psd.avg_supply_cost, tn.n_name
HAVING 
    COUNT(DISTINCT l.l_orderkey) >= 2
ORDER BY 
    total_value DESC NULLS LAST;
