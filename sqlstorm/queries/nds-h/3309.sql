
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
TopBrands AS (
    SELECT 
        p_brand,
        AVG(total_supply_cost) AS avg_supply_cost
    FROM 
        RankedParts
    WHERE 
        rank <= 5
    GROUP BY 
        p_brand
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS orders_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
HighSpendingCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name
    FROM 
        CustomerOrderSummary c
    WHERE 
        total_spent > (SELECT AVG(total_spent) FROM CustomerOrderSummary)
),
NationSupplier AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    n.n_name, 
    ns.supplier_count, 
    tb.p_brand,
    tb.avg_supply_cost,
    COUNT(DISTINCT h.c_custkey) AS high_spending_customers
FROM 
    NationSupplier ns
JOIN 
    nation n ON ns.n_name = n.n_name
FULL OUTER JOIN 
    TopBrands tb ON n.n_name = tb.p_brand
LEFT JOIN 
    HighSpendingCustomers h ON h.c_custkey IN (
        SELECT 
            DISTINCT o.o_custkey 
        FROM 
            orders o 
        JOIN 
            lineitem l ON o.o_orderkey = l.l_orderkey 
        WHERE 
            l.l_discount > 0.1
    )
GROUP BY 
    n.n_name, ns.supplier_count, tb.p_brand, tb.avg_supply_cost
HAVING 
    ns.supplier_count > 0
ORDER BY 
    n.n_name, tb.avg_supply_cost DESC;
