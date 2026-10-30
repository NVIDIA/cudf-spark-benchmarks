WITH RegionSupply AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        region r
    JOIN 
        nation n ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        n.n_name, r.r_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_line_item_price,
        COUNT(li.l_orderkey) AS line_item_count,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem li ON li.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CustomerPerformance AS (
    SELECT 
        c.c_name,
        SUM(od.total_line_item_price) AS total_spent,
        COUNT(DISTINCT od.o_orderkey) AS orders_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON o.o_custkey = c.c_custkey
    LEFT JOIN 
        OrderDetails od ON od.o_orderkey = o.o_orderkey
    GROUP BY 
        c.c_name
),
MaxSpend AS (
    SELECT 
        MAX(total_spent) AS max_spent_value
    FROM 
        CustomerPerformance
    WHERE 
        total_spent IS NOT NULL
),
SupplierRanks AS (
    SELECT 
        rs.nation_name,
        rs.region_name,
        rs.total_supply_cost,
        rs.supplier_count,
        RANK() OVER (PARTITION BY rs.region_name ORDER BY rs.total_supply_cost DESC) AS rank_within_region
    FROM 
        RegionSupply rs
)
SELECT 
    sp.nation_name,
    sp.region_name,
    CONCAT(sp.nation_name, ' in ', sp.region_name) AS full_location,
    sp.total_supply_cost,
    sp.supplier_count,
    cp.c_name AS premium_customer,
    cp.total_spent,
    cp.orders_count,
    CASE 
        WHEN cp.total_spent IS NULL THEN 'No Orders'
        ELSE CASE 
            WHEN cp.total_spent = (SELECT max_spent_value FROM MaxSpend) THEN 'Top Spender'
            ELSE 'Regular Spender'
        END
    END AS customer_type
FROM 
    SupplierRanks sp
LEFT JOIN 
    CustomerPerformance cp ON cp.total_spent > (SELECT max_spent_value FROM MaxSpend) / 2
WHERE 
    sp.rank_within_region = 1
ORDER BY 
    sp.total_supply_cost DESC, cp.total_spent DESC;
